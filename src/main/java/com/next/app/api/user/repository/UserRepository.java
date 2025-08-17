package com.next.app.api.user.repository;

import com.next.app.api.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByEmailAndDeletedFalse(String email);

    boolean existsByEmail(String email);

    boolean existsByEmailAndDeletedFalse(String email);

    List<User> findAllByDeletedFalse();
}
