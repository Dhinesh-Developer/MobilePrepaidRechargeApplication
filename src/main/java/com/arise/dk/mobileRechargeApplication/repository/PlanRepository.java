package com.arise.dk.mobileRechargeApplication.repository;

import com.arise.dk.mobileRechargeApplication.model.Plan;


import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PlanRepository extends JpaRepository<Plan, Long> {
    List<Plan> findByPlanCategory_CategoryName(String categoryName);  // ✅ Correct field reference
    
    @Modifying
    @Query("DELETE FROM Plan p WHERE p.planCategory.categoryId = :categoryId")
    void deleteByPlanCategoryId(@Param("categoryId") Long categoryId);

}
