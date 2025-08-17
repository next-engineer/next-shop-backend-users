package com.next.app.api.user.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "users", catalog = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 150)
    private String email; // 이메일 (로그인용, 유일)

    @Column(nullable = false)
    private String password; // 암호화 저장

    @Column(nullable = false, length = 100)
    private String name; // 사용자 이름

    @Column(nullable = false)
    private String deliveryAddress; // 배송지

    @Column(length = 20)
    private String phoneNumber; // 전화번호

    @Column(nullable = false, length = 20)
    private String role = "ROLE_USER"; // 권한

    @Column(nullable = false)
    private boolean deleted = false;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
