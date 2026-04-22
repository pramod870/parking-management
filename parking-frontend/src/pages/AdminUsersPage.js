// src/pages/AdminUsersPage.js
import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const ROLE_OPTS = ['ROLE_USER', 'ROLE_OPERATOR', 'ROLE_ADMIN'];
const ROLE_BADGE = { ROLE_ADMIN: 'badge-red', ROLE_OPERATOR: 'badge-yellow', ROLE_USER: 'badge-blue' };

function UserModal({ user, onClose, onSaved }) {
  const isNew = !user;
  const [form, setForm] = useState(
    user ? { name: user.name, role: user.roles?.[0] || 'ROLE_USER', is_active: user.is_active }
         : { name: '', email: '', password: '', phone: '', role: 'ROLE_USER' }
  );
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      let res;
      if (isNew) {
        res = await adminAPI.createUser(form);
      } else {
        res = await adminAPI.updateUser(user.id, { role: form.role, is_active: form.is_active, name: form.name });
      }
      onSaved(res.data);
    } catch (err) {
      setError(err.message || 'Failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-header">
          <span className="modal-title">{isNew ? 'Create User' : 'Edit User'}</span>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={submit}>
          <div className="form-group">
            <label className="form-label">Full Name</label>
            <input className="form-input" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
          </div>
          {isNew && (
            <>
              <div className="form-group">
                <label className="form-label">Email</label>
                <input className="form-input" type="email" value={form.email || ''} onChange={e => setForm({ ...form, email: e.target.value })} required />
              </div>
              <div className="form-group">
                <label className="form-label">Phone</label>
                <input className="form-input" type="tel" value={form.phone || ''} onChange={e => setForm({ ...form, phone: e.target.value })} />
              </div>
              <div className="form-group">
                <label className="form-label">Password</label>
                <input className="form-input" type="password" value={form.password || ''} onChange={e => setForm({ ...form, password: e.target.value })} required />
              </div>
            </>
          )}
          <div className="form-group">
            <label className="form-label">Role</label>
            <select className="form-select" value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}>
              {ROLE_OPTS.map(r => <option key={r} value={r}>{r.replace('ROLE_', '')}</option>)}
            </select>
          </div>
          {!isNew && (
            <div className="form-group">
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
                <span className="form-label" style={{ margin: 0 }}>Active Account</span>
              </label>
            </div>
          )}
          <div style={{ display: 'flex', gap: 10 }}>
            <button type="button" className="btn btn-ghost btn-full" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
              {loading ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function AdminUsersPage() {
  const [users, setUsers]       = useState([]);
  const [loading, setLoading]   = useState(true);
  const [modal, setModal]       = useState(null); // null | 'create' | user_obj
  const [search, setSearch]     = useState('');

  const load = async () => {
    setLoading(true);
    try { const r = await adminAPI.listUsers(); setUsers(r.data || []); }
    catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleDeactivate = async (id) => {
    if (!window.confirm('Deactivate this user?')) return;
    try {
      await adminAPI.deleteUser(id);
      setUsers(prev => prev.map(u => u.id === id ? { ...u, is_active: false } : u));
    } catch (err) { alert(err.message); }
  };

  const handleSaved = (saved) => {
    setUsers(prev => {
      const exists = prev.find(u => u.id === saved.id);
      return exists ? prev.map(u => u.id === saved.id ? saved : u) : [saved, ...prev];
    });
    setModal(null);
  };

  const filtered = users.filter(u =>
    u.name?.toLowerCase().includes(search.toLowerCase()) ||
    u.email?.toLowerCase().includes(search.toLowerCase())
  );

  const topRole = (roles) => {
    if (roles?.includes('ROLE_ADMIN'))    return 'ROLE_ADMIN';
    if (roles?.includes('ROLE_OPERATOR')) return 'ROLE_OPERATOR';
    return 'ROLE_USER';
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">User Management</h1>
          <p className="page-subtitle">{users.length} registered users</p>
        </div>
        <button className="btn btn-primary" onClick={() => setModal('create')}>+ Add User</button>
      </div>

      <div style={{ marginBottom: 20 }}>
        <input className="form-input" placeholder="🔍  Search by name or email..."
          value={search} onChange={e => setSearch(e.target.value)} style={{ maxWidth: 380 }} />
      </div>

      <div className="card">
        {loading ? (
          <div className="loading-screen" style={{ height: '40vh' }}><div className="spinner" /></div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th>Role</th><th>Status</th><th>Joined</th><th>Actions</th></tr></thead>
              <tbody>
                {filtered.map(u => (
                  <tr key={u.id}>
                    <td style={{ fontWeight: 600 }}>{u.name}</td>
                    <td style={{ color: 'var(--text2)', fontSize: 13 }}>{u.email}</td>
                    <td style={{ fontSize: 13, color: 'var(--text3)' }}>{u.phone || '—'}</td>
                    <td><span className={`badge ${ROLE_BADGE[topRole(u.roles)] || 'badge-gray'}`}>{topRole(u.roles).replace('ROLE_', '')}</span></td>
                    <td><span className={`badge ${u.is_active ? 'badge-green' : 'badge-red'}`}>{u.is_active ? 'Active' : 'Inactive'}</span></td>
                    <td style={{ fontSize: 12, color: 'var(--text3)' }}>{u.created_at?.split(' ')[0]}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button onClick={() => setModal(u)} className="btn btn-ghost btn-sm">Edit</button>
                        {u.is_active && (
                          <button onClick={() => handleDeactivate(u.id)} className="btn btn-danger btn-sm">Deactivate</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal && (
        <UserModal
          user={modal === 'create' ? null : modal}
          onClose={() => setModal(null)}
          onSaved={handleSaved}
        />
      )}
    </div>
  );
}
