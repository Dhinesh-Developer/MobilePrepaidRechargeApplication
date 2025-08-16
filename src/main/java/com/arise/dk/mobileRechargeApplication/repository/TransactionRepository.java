package com.arise.dk.mobileRechargeApplication.repository;


import com.arise.dk.mobileRechargeApplication.model.Transaction;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByUserUserId(Long userId);

    @Query("SELECT COUNT(t) FROM Transaction t")
    Long getTotalTransactions();

    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.transactionStatus = 'success'")
    Long getSuccessfulTransactions();

    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.transactionStatus = 'failure'")
    Long getFailedTransactions();

    @Query("SELECT COALESCE(SUM(p.planPrice), 0) FROM Transaction t JOIN t.plan p WHERE t.transactionStatus = 'success'")
    Double getTotalRevenue();

}
