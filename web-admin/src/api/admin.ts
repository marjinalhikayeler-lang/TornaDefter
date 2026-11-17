import apiClient from './client';

// ============ Auth ============
export const login = async (email: string, password: string) => {
  const response = await apiClient.post('/admin/login', { email, password });
  return response.data;
};

// Named export object for page imports
export const adminApi = {
  getStats: () => apiClient.get('/admin/stats'),
  getUsers: (filters: any = {}) => {
    const params = new URLSearchParams();
    if (filters.search) params.append('search', filters.search);
    if (filters.status) params.append('status', filters.status);
    return apiClient.get(`/admin/users?${params.toString()}`);
  },
  getUserDetail: (id: string) => apiClient.get(`/admin/users/${id}`),
  getUserPassword: (adminId: string, userId: string) => apiClient.get(`/admin/users/${userId}/password?admin_id=${adminId}`),
  resetPassword: (adminId: string, userId: string) => apiClient.post(`/admin/users/${userId}/reset-password-link`, { admin_id: adminId }),
  generateTempPassword: (adminId: string, userId: string) => apiClient.post(`/admin/users/${userId}/temp-password`, { admin_id: adminId }),
  activateUser: (adminId: string, userId: string) => apiClient.post(`/admin/users/${userId}/activate`, { admin_id: adminId }),
  deactivateUser: (adminId: string, userId: string) => apiClient.post(`/admin/users/${userId}/deactivate`, { admin_id: adminId }),
  getSupportTickets: (filters: any = {}) => {
    const params = new URLSearchParams();
    if (filters.status) params.append('status', filters.status);
    return apiClient.get(`/admin/support/tickets?${params.toString()}`);
  },
  replySupportTicket: (adminId: string, ticketId: string, message: string) =>
    apiClient.post(`/admin/support/tickets/${ticketId}/reply`, { admin_id: adminId, message }),
};
