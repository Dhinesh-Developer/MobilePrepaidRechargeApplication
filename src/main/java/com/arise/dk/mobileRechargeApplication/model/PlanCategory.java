package com.arise.dk.mobileRechargeApplication.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.ArrayList;
import java.util.List;
import com.fasterxml.jackson.annotation.JsonManagedReference;

@Entity
@Table(name = "PlanCategories")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlanCategory {
	
	
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long categoryId;
    
    @Column(nullable = false, unique = true, length = 100)
    private String categoryName;
    
    @Column(nullable = false, unique = true, length = 100)
    private String categoryDisplayName;
    
    @OneToMany(mappedBy = "planCategory", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private List<Plan> plans = new ArrayList<>();
}
