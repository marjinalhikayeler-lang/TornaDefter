import { useState, useEffect } from 'react';
import { adminApi } from '../api/admin';

const statCards = [
  { key: 'total_users', label: 'Toplam Kullanıcı', color: 'bg-blue-600', icon: '👥' },
  { key: 'active_users', label: 'Aktif Kullanıcı', color: 'bg-green-600', icon: '✅' },
  { key: 'total_companies', label: 'Toplam Firma', color: 'bg-purple-600', icon: '🏢' },
  { key: 'total_transactions', label: 'Toplam İşlem', color: 'bg-orange-600', icon: '📊' },
  { key: 'total_accounts', label: 'Toplam Cari', color: 'bg-cyan-600', icon: '📋' },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi.getStats().then(res => { setStats(res.data); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold text-white mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        {statCards.map(card => (
          <div key={card.key} className={`${card.color} rounded-xl p-5 text-white`}>
            <div className="text-3xl mb-2">{card.icon}</div>
            <div className="text-3xl font-bold">{loading ? '...' : (stats?.[card.key]?.toLocaleString('tr-TR') || 0)}</div>
            <div className="text-sm opacity-80 mt-1">{card.label}</div>
          </div>
        ))}
      </div>
      <div className="bg-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Hoş Geldiniz</h2>
        <p className="text-slate-400">TornaDefter yönetim paneline hoş geldiniz. Sol menüden kullanıcıları yönetebilir, destek taleplerini inceleyebilir ve sistem istatistiklerini görüntüleyebilirsiniz.</p>
      </div>
    </div>
  );
}

