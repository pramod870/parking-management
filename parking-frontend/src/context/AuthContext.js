// src/context/AuthContext.js
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser]       = useState(null);
  const [token, setToken]     = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  const loadProfile = useCallback(async () => {
    if (!localStorage.getItem('token')) { setLoading(false); return; }
    try {
      const data = await authAPI.profile();
      setUser(data.user);
    } catch {
      localStorage.removeItem('token');
      setToken(null);
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadProfile(); }, [loadProfile]);

  const login = async (email, password) => {
    const data = await authAPI.login(email, password);
    localStorage.setItem('token', data.token);
    setToken(data.token);
    // Decode user from token payload
    try {
      const payload = JSON.parse(atob(data.token.split('.')[1]));
      setUser({ id: payload.id, email: payload.email, name: payload.name, roles: payload.roles });
    } catch {
      await loadProfile();
    }
    return data;
  };

  const logout = () => {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
  };

  const hasRole = (role) => user?.roles?.includes(role) || false;
  const isAdmin    = () => hasRole('ROLE_ADMIN');
  const isOperator = () => hasRole('ROLE_OPERATOR') || hasRole('ROLE_ADMIN');

  return (
    <AuthContext.Provider value={{ user, token, loading, login, logout, hasRole, isAdmin, isOperator }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
