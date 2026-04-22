// src/components/Layout.js
import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const NAV = [
  { to: '/',             icon: '⬡', label: 'Dashboard',    roles: ['all'] },
  { to: '/lots',         icon: '🅿',  label: 'Parking Lots', roles: ['all'] },
  { to: '/sessions',     icon: '🚗', label: 'Sessions',     roles: ['ROLE_OPERATOR', 'ROLE_ADMIN'] },
  { to: '/entry-exit',   icon: '⇄',  label: 'Entry / Exit', roles: ['ROLE_OPERATOR', 'ROLE_ADMIN'] },
  { to: '/bookings',     icon: '📅', label: 'Bookings',     roles: ['all'] },
  { to: '/admin/users',  icon: '👥', label: 'Users',        roles: ['ROLE_ADMIN'] },
  { to: '/profile',      icon: '◉',  label: 'Profile',      roles: ['all'] },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);

  const canSee = (roles) => {
    if (roles.includes('all')) return true;
    return roles.some(r => user?.roles?.includes(r));
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const roleLabel = user?.roles?.includes('ROLE_ADMIN')
    ? 'Admin' : user?.roles?.includes('ROLE_OPERATOR')
    ? 'Operator' : 'User';

  const roleBadge = user?.roles?.includes('ROLE_ADMIN')
    ? 'badge-red' : user?.roles?.includes('ROLE_OPERATOR')
    ? 'badge-yellow' : 'badge-blue';

  return (
    <div style={{ display: 'flex', minHeight: '100vh', position: 'relative', zIndex: 1 }}>

      {/* Mobile overlay */}
      {open && (
        <div onClick={() => setOpen(false)} style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,.6)',
          zIndex: 40, display: 'none'
        }} className="mobile-overlay" />
      )}

      {/* Sidebar */}
      <aside style={{
        width: 240, background: 'var(--surface)', borderRight: '1px solid var(--border)',
        display: 'flex', flexDirection: 'column', position: 'fixed', top: 0, bottom: 0, left: 0,
        zIndex: 50, transition: 'transform .25s ease',
      }}>
        {/* Logo */}
        <div style={{ padding: '24px 20px 16px', borderBottom: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 36, height: 36, background: 'var(--accent)',
              borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 18, fontWeight: 800, color: '#fff',
            }}>P</div>
            <div>
              <div style={{ fontWeight: 800, fontSize: 16, letterSpacing: -.3 }}>ParkOS</div>
              <div style={{ fontSize: 11, color: 'var(--text3)', letterSpacing: 1 }}>MANAGEMENT</div>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav style={{ flex: 1, padding: '12px 0', overflowY: 'auto' }}>
          {NAV.filter(n => canSee(n.roles)).map(({ to, icon, label }) => (
            <NavLink key={to} to={to} end={to === '/'} style={({ isActive }) => ({
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 20px', margin: '2px 8px',
              borderRadius: 8, textDecoration: 'none', fontSize: 14, fontWeight: 500,
              color: isActive ? '#fff' : 'var(--text2)',
              background: isActive ? 'var(--accent)' : 'transparent',
              transition: 'all .15s',
            })}
            onMouseEnter={e => { if (!e.currentTarget.style.background.includes('accent')) e.currentTarget.style.background = 'var(--surface2)'; }}
            onMouseLeave={e => { if (!e.currentTarget.style.background.includes('accent')) e.currentTarget.style.background = 'transparent'; }}
            >
              <span style={{ fontSize: 16, width: 20, textAlign: 'center' }}>{icon}</span>
              {label}
            </NavLink>
          ))}
        </nav>

        {/* User info */}
        <div style={{ padding: '16px 20px', borderTop: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
            <div style={{
              width: 34, height: 34, background: 'var(--surface3)',
              borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 700, color: 'var(--accent)',
              border: '2px solid var(--border)',
            }}>
              {user?.name?.[0]?.toUpperCase() || 'U'}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {user?.name}
              </div>
              <span className={`badge ${roleBadge}`} style={{ fontSize: 10, padding: '1px 7px' }}>{roleLabel}</span>
            </div>
          </div>
          <button onClick={handleLogout} className="btn btn-ghost btn-full btn-sm">
            ⏻ Logout
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ marginLeft: 240, flex: 1, padding: '28px 32px', minHeight: '100vh' }}>
        <Outlet />
      </main>
    </div>
  );
}
