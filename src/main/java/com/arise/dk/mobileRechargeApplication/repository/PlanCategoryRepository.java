package com.arise.dk.mobileRechargeApplication.repository;

import com.arise.dk.mobileRechargeApplication.model.PlanCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface PlanCategoryRepository extends JpaRepository<PlanCategory, Long> {
    Optional<PlanCategory> findByCategoryName(String categoryName);  // ✅ Find category by name
}
