// src/pages/LoginPage.js
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate  = useNavigate();
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError]   = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await login(form.email, form.password);
      navigate('/');
    } catch (err) {
      setError(err.message || 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  const fill = (email, password) => setForm({ email, password });

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 20, position: 'relative', zIndex: 1,
    }}>
      <div style={{ width: '100%', maxWidth: 420 }}>

        {/* Logo */}
        <div style={{ textAlign: 'center', marginBottom: 36 }}>
          <div style={{
            width: 56, height: 56, background: 'var(--accent)', borderRadius: 16,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 26, fontWeight: 900, color: '#fff', margin: '0 auto 14px',
            boxShadow: '0 8px 32px rgba(59,130,246,.3)',
          }}>P</div>
          <h1 style={{ fontSize: 28, fontWeight: 800, letterSpacing: -.5 }}>ParkOS</h1>
          <p style={{ color: 'var(--text2)', fontSize: 14, marginTop: 4 }}>Parking Management System</p>
        </div>

        <div className="card">
          <h2 style={{ fontSize: 20, fontWeight: 700, marginBottom: 6 }}>Welcome back</h2>
          <p style={{ color: 'var(--text2)', fontSize: 13, marginBottom: 24 }}>Sign in to your account</p>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                className="form-input"
                type="email"
                placeholder="you@example.com"
                value={form.email}
                onChange={e => setForm({ ...form, email: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Password</label>
              <input
                className="form-input"
                type="password"
                placeholder="••••••••"
                value={form.password}
                onChange={e => setForm({ ...form, password: e.target.value })}
                required
              />
            </div>
            <button type="submit" className="btn btn-primary btn-full btn-lg" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          {/* Quick fill buttons */}
          <div style={{ marginTop: 24 }}>
            <p style={{ fontSize: 11, color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10 }}>
              Quick Test Login
            </p>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {[
                { label: 'Admin',    e: 'admin@parking.com',    p: 'Admin@123',    cls: 'badge-red' },
                { label: 'Operator', e: 'operator@parking.com', p: 'Operator@123', cls: 'badge-yellow' },
                { label: 'User',     e: 'user@parking.com',     p: 'User@123',     cls: 'badge-blue' },
              ].map(({ label, e, p, cls }) => (
                <button key={label} className={`badge ${cls}`} style={{ cursor: 'pointer', border: 'none', padding: '5px 12px' }}
                  onClick={() => fill(e, p)}>
                  {label}
                </button>
              ))}
            </div>
          </div>
        </div>

        <p style={{ textAlign: 'center', marginTop: 20, color: 'var(--text2)', fontSize: 14 }}>
          Don't have an account?{' '}
          <Link to="/register" style={{ color: 'var(--accent)', fontWeight: 600 }}>Register</Link>
        </p>
      </div>
    </div>
  );
}
