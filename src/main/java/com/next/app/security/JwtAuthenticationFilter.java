package com.next.app.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private final JwtTokenProvider tokenProvider;

    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    /** ✅ 브라우저 CORS 프리플라이트(OPTIONS)는 필터 제외 */
    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        return "OPTIONS".equalsIgnoreCase(request.getMethod());
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            log.trace("Skip JWT filter for CORS preflight: {}", request.getRequestURI());
            filterChain.doFilter(request, response);
            return;
        }

        // 이미 인증돼 있지 않은 경우만 처리
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            String token = tokenProvider.resolveToken(request);

            if (token != null && tokenProvider.validateToken(token)) {
                Long userId = tokenProvider.getUserId(token);
                if (userId != null) {
                    String email = tokenProvider.getEmailFromToken(token);
                    List<String> roles = tokenProvider.getRoles(token);
                    var authorities = roles.stream().map(SimpleGrantedAuthority::new).toList();

                    var principal = new CustomUserPrincipal(userId, email, authorities);
                    var authentication = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                } else {
                    log.trace("Valid JWT but missing userId claim for {}", request.getRequestURI());
                }
            } else if (token != null) {
                log.trace("Invalid/expired JWT for {}", request.getRequestURI());
            }
        }

        filterChain.doFilter(request, response);
    }
}