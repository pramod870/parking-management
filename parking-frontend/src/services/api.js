// src/services/api.js
const BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

const getToken = () => localStorage.getItem('token');

const headers = (extra = {}) => ({
  'Content-Type': 'application/json',
  ...(getToken() ? { Authorization: `Bearer ${getToken()}` } : {}),
  ...extra,
});

const handleRes = async (res) => {
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw { status: res.status, message: data.error || 'Request failed', data };
  return data;
};

// ── Auth ─────────────────────────────────────────────────────
export const authAPI = {
  login: (email, password) =>
    fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({ email, password }),
    }).then(handleRes),

  register: (payload) =>
    fetch(`${BASE_URL}/auth/register`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  profile: () =>
    fetch(`${BASE_URL}/auth/profile`, { headers: headers() }).then(handleRes),

  updateProfile: (payload) =>
    fetch(`${BASE_URL}/auth/profile`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),
};

// ── Parking Lots ─────────────────────────────────────────────
export const lotsAPI = {
  list: () =>
    fetch(`${BASE_URL}/lots`, { headers: headers() }).then(handleRes),

  get: (id) =>
    fetch(`${BASE_URL}/lots/${id}`, { headers: headers() }).then(handleRes),

  create: (payload) =>
    fetch(`${BASE_URL}/lots`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  update: (id, payload) =>
    fetch(`${BASE_URL}/lots/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  delete: (id) =>
    fetch(`${BASE_URL}/lots/${id}`, {
      method: 'DELETE',
      headers: headers(),
    }).then(handleRes),

  slots: (id) =>
    fetch(`${BASE_URL}/lots/${id}/slots`, { headers: headers() }).then(handleRes),
};

// ── Sessions ─────────────────────────────────────────────────
export const sessionsAPI = {
  list: () =>
    fetch(`${BASE_URL}/sessions`, { headers: headers() }).then(handleRes),

  get: (id) =>
    fetch(`${BASE_URL}/sessions/${id}`, { headers: headers() }).then(handleRes),

  entry: (payload) =>
    fetch(`${BASE_URL}/sessions/entry`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  exit: (id, paymentMethod = 'cash') =>
    fetch(`${BASE_URL}/sessions/${id}/exit`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({ payment_method: paymentMethod }),
    }).then(handleRes),

  pay: (id, transactionId) =>
    fetch(`${BASE_URL}/sessions/${id}/pay`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({ transaction_id: transactionId }),
    }).then(handleRes),
};

// ── Bookings ─────────────────────────────────────────────────
export const bookingsAPI = {
  list: () =>
    fetch(`${BASE_URL}/bookings`, { headers: headers() }).then(handleRes),

  get: (id) =>
    fetch(`${BASE_URL}/bookings/${id}`, { headers: headers() }).then(handleRes),

  create: (payload) =>
    fetch(`${BASE_URL}/bookings`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  cancel: (id) =>
    fetch(`${BASE_URL}/bookings/${id}`, {
      method: 'DELETE',
      headers: headers(),
    }).then(handleRes),
};

// ── Dashboard ─────────────────────────────────────────────────
export const dashboardAPI = {
  stats: () =>
    fetch(`${BASE_URL}/dashboard/stats`, { headers: headers() }).then(handleRes),

  revenue: (from, to) =>
    fetch(`${BASE_URL}/dashboard/revenue?from=${from}&to=${to}`, { headers: headers() }).then(handleRes),
};

// ── Admin ─────────────────────────────────────────────────────
export const adminAPI = {
  listUsers: () =>
    fetch(`${BASE_URL}/admin/users`, { headers: headers() }).then(handleRes),

  createUser: (payload) =>
    fetch(`${BASE_URL}/admin/users`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  updateUser: (id, payload) =>
    fetch(`${BASE_URL}/admin/users/${id}`, {
      method: 'PUT',
      headers: headers(),
      body: JSON.stringify(payload),
    }).then(handleRes),

  deleteUser: (id) =>
    fetch(`${BASE_URL}/admin/users/${id}`, {
      method: 'DELETE',
      headers: headers(),
    }).then(handleRes),
};
