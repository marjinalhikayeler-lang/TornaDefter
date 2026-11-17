import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { adminApi } from '../api/admin';

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [meta, setMeta] = useState<any>({});
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const fetchUsers = (s?: string, st?: string) => {
    setLoading(true);
    adminApi.getUsers({ search: s ?? search, status: st ?? status })
      .then(res => { setUsers(res.data.data); setMeta(res.data.meta); setLoading(false); })
      .catch(() => setLoading(false));
  };

  useEffect(() => { fetchUsers(); }, []);

  const handleSearch = () => fetchUsers();
  const handleFilter = (s: string) => { setStatus(s); fetchUsers(search, s); };

  const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('tr-TR') : '-';

  return (
    <div>
      <h1 className="text-2xl font-bold text-white mb-4">Kullanıcılar</h1>
      {/* Özet */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-slate-800 rounded-xl p-4"><div className="text-2xl font-bold text-white">{meta.total || 0}</div><div className="text-slate-400 text-sm">Toplam</div></div>
        <div className="bg-slate-800 rounded-xl p-4"><div className="text-2xl font-bold text-green-400">{meta.active_count || 0}</div><div className="text-slate-400 text-sm">Aktif</div></div>
        <div className="bg-slate-800 rounded-xl p-4"><div className="text-2xl font-bold text-blue-400">{meta.today_registrations || 0}</div><div className="text-slate-400 text-sm">Bugün Kayıt</div></div>
      </div>
      {/* Arama & Filtre */}
      <div className="flex gap-3 mb-4">
        <input value={search} onChange={e => setSearch(e.target.value)} onKeyDown={e => e.key === 'Enter' && handleSearch()}
          className="flex-1 bg-slate-700 text-white rounded-lg px-4 py-2 outline-none focus:ring-2 focus:ring-blue-500" placeholder="Ad, e-posta veya telefon ara..." />
        <button onClick={handleSearch} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">Ara</button>
        {['', 'active', 'inactive'].map(s => (
          <button key={s} onClick={() => handleFilter(s)}
            className={`px-3 py-2 rounded-lg text-sm ${status === s ? 'bg-blue-600 text-white' : 'bg-slate-700 text-slate-300 hover:bg-slate-600'}`}>
            {s === '' ? 'Tümü' : s === 'active' ? 'Aktif' : 'Pasif'}
          </button>
        ))}
      </div>
      {/* Tablo */}
      <div className="bg-slate-800 rounded-xl overflow-hidden">
        <table className="w-full">
          <thead><tr className="border-b border-slate-700">
            {['Ad Soyad', 'E-posta', 'Telefon', 'Firma', 'Durum', 'Son Giriş', 'Kayıt', ''].map(h => (
              <th key={h} className="text-left text-slate-400 text-sm font-medium px-4 py-3">{h}</th>
            ))}
          </tr></thead>
          <tbody>
            {loading ? <tr><td colSpan={8} className="text-center text-slate-400 py-8">Yükleniyor...</td></tr> :
            users.length === 0 ? <tr><td colSpan={8} className="text-center text-slate-400 py-8">Kullanıcı bulunamadı</td></tr> :
            users.map(u => (
              <tr key={u.id} className="border-b border-slate-700/50 hover:bg-slate-700/30 cursor-pointer" onClick={() => navigate(`/users/${u.id}`)}>
                <td className="px-4 py-3 text-white font-medium">{u.first_name} {u.last_name}</td>
                <td className="px-4 py-3 text-slate-300">{u.email}</td>
                <td className="px-4 py-3 text-slate-300">{u.phone || '-'}</td>
                <td className="px-4 py-3 text-slate-300">{u._count?.owned_companies || 0}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${u.is_active ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
                    {u.is_active ? 'Aktif' : 'Pasif'}
                  </span>
                </td>
                <td className="px-4 py-3 text-slate-400 text-sm">{formatDate(u.last_login_at)}</td>
                <td className="px-4 py-3 text-slate-400 text-sm">{formatDate(u.created_at)}</td>
                <td className="px-4 py-3"><button className="text-blue-400 hover:text-blue-300 text-sm">Detay →</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

