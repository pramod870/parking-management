// src/App.js
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import DashboardPage from './pages/DashboardPage';
import LotsPage from './pages/LotsPage';
import LotDetailPage from './pages/LotDetailPage';
import SessionsPage from './pages/SessionsPage';
import EntryExitPage from './pages/EntryExitPage';
import BookingsPage from './pages/BookingsPage';
import AdminUsersPage from './pages/AdminUsersPage';
import ProfilePage from './pages/ProfilePage';
import './App.css';

function PrivateRoute({ children, requireAdmin, requireOperator }) {
  const { user, loading } = useAuth();
  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;
  if (!user)   return <Navigate to="/login" replace />;
  if (requireAdmin    && !user.roles?.includes('ROLE_ADMIN'))    return <Navigate to="/" replace />;
  if (requireOperator && !user.roles?.includes('ROLE_OPERATOR') && !user.roles?.includes('ROLE_ADMIN'))
    return <Navigate to="/" replace />;
  return children;
}

function PublicRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;
  if (user)    return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login"    element={<PublicRoute><LoginPage /></PublicRoute>} />
          <Route path="/register" element={<PublicRoute><RegisterPage /></PublicRoute>} />

          <Route path="/" element={<PrivateRoute><Layout /></PrivateRoute>}>
            <Route index element={<DashboardPage />} />
            <Route path="lots"         element={<LotsPage />} />
            <Route path="lots/:id"     element={<LotDetailPage />} />
            <Route path="sessions"     element={<PrivateRoute requireOperator><SessionsPage /></PrivateRoute>} />
            <Route path="entry-exit"   element={<PrivateRoute requireOperator><EntryExitPage /></PrivateRoute>} />
            <Route path="bookings"     element={<BookingsPage />} />
            <Route path="admin/users"  element={<PrivateRoute requireAdmin><AdminUsersPage /></PrivateRoute>} />
            <Route path="profile"      element={<ProfilePage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
