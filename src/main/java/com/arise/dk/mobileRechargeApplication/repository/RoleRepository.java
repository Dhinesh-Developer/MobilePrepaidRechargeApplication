package com.arise.dk.mobileRechargeApplication.repository;

import com.arise.dk.mobileRechargeApplication.model.Role;
import com.arise.dk.mobileRechargeApplication.model.Role.RoleName;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByRoleName(RoleName roleName);
}
