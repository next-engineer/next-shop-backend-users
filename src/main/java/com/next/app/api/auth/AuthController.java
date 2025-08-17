package com.next.app.api.auth;

import com.next.app.api.user.entity.User;
import com.next.app.api.user.repository.UserRepository;
import com.next.app.security.JwtTokenProvider;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid credentials");
        }

        List<String> roles = user.getRole() != null ?
                List.of(user.getRole()) : List.of("ROLE_USER");

        String token = jwtTokenProvider.createToken(user.getId(), user.getEmail(), roles);

        return ResponseEntity.ok(new TokenResponse("Bearer", token));
    }

    @Data
    @AllArgsConstructor
    public static class TokenResponse {
        private String tokenType;
        private String accessToken;
    }
}
