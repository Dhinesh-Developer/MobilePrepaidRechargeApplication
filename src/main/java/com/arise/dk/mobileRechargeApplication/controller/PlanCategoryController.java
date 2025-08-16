package com.arise.dk.mobileRechargeApplication.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arise.dk.mobileRechargeApplication.model.PlanCategory;
import com.arise.dk.mobileRechargeApplication.service.PlanCategoryService;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class PlanCategoryController {
	
	private final PlanCategoryService planCategoryService;
	
	public PlanCategoryController(PlanCategoryService planCategoryService) {
		this.planCategoryService = planCategoryService;
	}
	
	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
	@GetMapping("/both/Category/getCategory")
	public List<PlanCategory> getPlanCategories(){
		return planCategoryService.getAllCategories();
	}
	
	@PreAuthorize("hasAuthority('ADMIN')")
	@PostMapping("/admin/Category/addCategory")
	public ResponseEntity<?> addNewCategory(@RequestBody PlanCategory category){
		PlanCategory planCategory = planCategoryService.addNewCategory(category);
		
		return new ResponseEntity<>(planCategory , HttpStatus.CREATED);
	}
	
	@PreAuthorize("hasAuthority('ADMIN')")
	@PostMapping("/admin/Category/delete")
	public ResponseEntity<String> deleteCategories(@RequestBody Map<String, List<Long>> request) {
	    List<Long> categoryIds = request.get("categoryIds");
	    
	    planCategoryService.deleteAllById(categoryIds);
	    
	    return ResponseEntity.ok("Categories deleted successfully.");
	}
}
