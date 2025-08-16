package com.arise.dk.mobileRechargeApplication.service;

import com.arise.dk.mobileRechargeApplication.model.Transaction;
import com.arise.dk.mobileRechargeApplication.repository.TransactionRepository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

@Service
public class TransactionService {
    private final TransactionRepository transactionRepository;

    public TransactionService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }
    
    
    public List<Transaction> getAllTransactions(String name, String mode) {
    	List<Transaction> transactions = transactionRepository.findAll();
    	if(!(mode.equals("All"))) transactions = transactions.stream().filter(user -> user.getTransactionMode().name().equals(mode)).collect(Collectors.toList());
    	if(name.equals("Success")) {
            return transactions.stream().filter(user -> (user.getTransactionStatus().name()).equals("SUCCESS")).collect(Collectors.toList());
    	}
    	else if(name.equals("Failure")) {
            return transactions.stream().filter(user -> (user.getTransactionStatus().name()).equals("FAILURE")).collect(Collectors.toList());
    	}
    	else if(name.equals("Pending")) {
            return transactions.stream().filter(user -> (user.getTransactionStatus().name()).equals("PENDING")).collect(Collectors.toList());
    	}
    	else if(!(name.equals("All"))) {
    		transactions = transactions.stream().filter(user -> (user.getUser().getUserFname()+user.getUser().getUserLname()).toLowerCase().contains(name)).collect(Collectors.toList());
    	}
 
    	return transactions;
    }
    
    public List<Transaction> getTransactionsByUserId(Long userId) {
        return transactionRepository.findByUserUserId(userId);
    }

    // Add a new transaction
    public Transaction createTransaction(Transaction transaction) {
        return transactionRepository.save(transaction);
    }
    
    public long getTotalTransactions() {
        return transactionRepository.getTotalTransactions();
    }

    public long getSuccessfulTransactions() {
        return transactionRepository.getSuccessfulTransactions();
    }

    public long getFailedTransactions() {
        return transactionRepository.getFailedTransactions();
    }

    public double getTotalRevenue() {
        return transactionRepository.getTotalRevenue();
    }


	public Optional<Transaction> getTransactionsById(Long transactionId) {
		
		return transactionRepository.findById(transactionId);
	}
}
