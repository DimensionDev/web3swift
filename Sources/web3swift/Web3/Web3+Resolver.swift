//
//  Web3+Resolver.swift
//
//
//  Created by Jann Driessen on 01.11.22.
//

import Foundation
import BigInt
import Web3Core

public class PolicyResolver {
    private let provider: Web3Provider

    public init(provider: Web3Provider) {
        self.provider = provider
    }

    public func resolveAllAggressive(for tx: inout CodableTransaction, with policies: Policies = .auto) async throws {
        guard tx.from != nil || tx.sender != nil else {
            throw Web3Error.valueError(desc: "from and sender are nil")
        }
    
        var snapshot = tx // safe snapshot for parallel estimate
    
        async let nonceAsync = resolveNonce(for: tx, with: policies.noncePolicy)
        if case .eip1559 = tx.type {
            async let baseFeeAsync = resolveGasBaseFee(for: policies.maxFeePerGasPolicy)
            async let priorityFeeAsync = resolveGasPriorityFee(for: policies.maxPriorityFeePerGasPolicy)
            async let gasLimitAsync = resolveGasEstimate(for: snapshot, with: policies.gasLimitPolicy) // 不等 nonce
    
            tx.nonce = try await nonceAsync
            tx.gasLimit = try await gasLimitAsync
            let baseFee = try await baseFeeAsync
            let priority = try await priorityFeeAsync
            tx.maxPriorityFeePerGas = priority
            tx.maxFeePerGas = baseFee + priority
        } else {
            async let gasPriceAsync = resolveGasPrice(for: policies.gasPricePolicy)
            async let gasLimitAsync = resolveGasEstimate(for: snapshot, with: policies.gasLimitPolicy) // 不等 nonce
    
            tx.nonce = try await nonceAsync
            tx.gasLimit = try await gasLimitAsync
            tx.gasPrice = try await gasPriceAsync
        }
    }

    public func resolveAll(for tx: CodableTransaction, with policies: Policies = .auto) async throws -> CodableTransaction {
        var tx = tx
        try await resolveAll(for: &tx, with: policies)
        return tx
    }

    public func resolveGasBaseFee(for policy: ValueResolutionPolicy) async -> BigUInt {
        switch policy {
        case .automatic:
            return await Oracle(provider).baseFeePercentiles().max() ?? 0
        case .manual(let value):
            return value
        }
    }

    public func resolveGasEstimate(for transaction: CodableTransaction, with policy: ValueResolutionPolicy) async throws -> BigUInt {
        switch policy {
        case .automatic:
            return try await estimateGas(for: transaction)
        case .manual(let value):
            return value
        }
    }

    public func resolveGasPrice(for policy: ValueResolutionPolicy) async -> BigUInt {
        switch policy {
        case .automatic:
            return await Oracle(provider).gasPriceLegacyPercentiles().max() ?? 0
        case .manual(let value):
            return value
        }
    }

    public func resolveGasPriorityFee(for policy: ValueResolutionPolicy) async -> BigUInt {
        switch policy {
        case .automatic:
            return await Oracle(provider).tipFeePercentiles().max() ?? 0
        case .manual(let value):
            return value
        }
    }

    public func resolveNonce(for tx: CodableTransaction, with policy: NoncePolicy) async throws -> BigUInt {
        switch policy {
        case .pending, .latest, .earliest:
            guard let address = tx.from ?? tx.sender else { throw Web3Error.valueError() }
            let request: APIRequest = .getTransactionCount(address.address, tx.callOnBlock ?? .latest)
            let response: APIResponse<BigUInt> = try await APIRequest.sendRequest(with: provider, for: request)
            return response.result
        case .exact(let value):
            return value
        }
    }
}

// MARK: - Private

extension PolicyResolver {
    private func estimateGas(for transaction: CodableTransaction) async throws -> BigUInt {
        let request: APIRequest = .estimateGas(transaction, transaction.callOnBlock ?? .latest)
        let response: APIResponse<BigUInt> = try await APIRequest.sendRequest(with: provider, for: request)
        return response.result
    }
}
