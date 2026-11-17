import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { adminApi } from '../api/admin';
import { useAuth } from '../context/AuthContext';

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [password, setPassword] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState('');
  const [tempPassword, setTempPassword] = useState<string | null>(null);
  const { adminId } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (id) adminApi.getUserDetail(id).then(r => { setUser(r.data); setLoading(false); }).catch(() => setLoading(false));
  }, [id]);

  const handleShowPassword = async () => {
    if (!adminId || !id) return;
    setPasswordLoading(true);
    try {
      const res = await adminApi.getUserPassword(adminId, id);
      const val = res.data.password || res.data.password_plain || res.data.message || 'Şifre bulunamadı';
      setPassword(val);
    } catch { setPassword('Şifre alınamadı'); }
    setPasswordLoading(false);
  };

  const handleTempPassword = async () => {
    if (!adminId || !id) return;
    setActionLoading('temp');
    try {
      const res = await adminApi.generateTempPassword(adminId, id);
      setTempPassword(res.data.temp_password);
    } catch {}
    setActionLoading('');
  };

  const handleToggleActive = async () => {
    if (!adminId || !id) return;
    setActionLoading('toggle');
    try {
      if (user.is_active) await adminApi.deactivateUser(adminId, id);
      else await adminApi.activateUser(adminId, id);
      setUser({ ...user, is_active: !user.is_active });
    } catch {}
    setActionLoading('');
  };

  const handleResetLink = async () => {
    if (!adminId || !id) return;
    setActionLoading('reset');
    try { await adminApi.resetPassword(adminId, id); alert('Şifre sıfırlama linki gönderildi'); } catch {}
    setActionLoading('');
  };

  const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('tr-TR', { day: '2-digit', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-';

  if (loading) return <div className="text-slate-400 text-center py-20">Yükleniyor...</div>;
  if (!user) return <div className="text-red-400 text-center py-20">Kullanıcı bulunamadı</div>;

  return (
    <div>
      <button onClick={() => navigate('/users')} className="text-blue-400 hover:text-blue-300 mb-4 inline-block">← Kullanıcılara Dön</button>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Sol: Kullanıcı bilgileri */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-slate-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white">{user.first_name} {user.last_name}</h2>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${user.is_active ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
                {user.is_active ? 'Aktif' : 'Pasif'}
              </span>
            </div>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div><span className="text-slate-400">E-posta:</span><p className="text-white">{user.email}</p></div>
              <div><span className="text-slate-400">Telefon:</span><p className="text-white">{user.phone || '-'}</p></div>
              <div><span className="text-slate-400">Kayıt Tarihi:</span><p className="text-white">{formatDate(user.created_at)}</p></div>
              <div><span className="text-slate-400">Son Giriş:</span><p className="text-white">{formatDate(user.last_login_at)}</p></div>
            </div>
          </div>

          {/* ŞİFRE GÖRÜNTÜLEME */}
          <div className="bg-slate-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">🔑 Şifre Yönetimi</h3>
            <div className="space-y-3">
              {/* Şifreyi Göster */}
              {!showPasswordModal ? (
                <button onClick={() => setShowPasswordModal(true)} className="bg-amber-600 hover:bg-amber-700 text-white px-4 py-2 rounded-lg text-sm font-medium w-full">
                  🔓 Kullanıcı Şifresini Göster
                </button>
              ) : (
                <div className="bg-slate-700 rounded-lg p-4">
                  {password === null ? (
                    <div>
                      <p className="text-amber-400 text-sm mb-3">⚠️ Bu işlem denetim kaydına yazılacaktır. Devam etmek istiyor musunuz?</p>
                      <div className="flex gap-2">
                        <button onClick={handleShowPassword} disabled={passwordLoading} className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm disabled:opacity-50">
                          {passwordLoading ? 'Yükleniyor...' : 'Evet, Göster'}
                        </button>
                        <button onClick={() => setShowPasswordModal(false)} className="bg-slate-600 hover:bg-slate-500 text-white px-4 py-2 rounded-lg text-sm">İptal</button>
                      </div>
                    </div>
                  ) : (
                    <div>
                      <p className="text-slate-400 text-sm mb-1">Kullanıcı Şifresi:</p>
                      <p className="text-2xl font-mono text-white bg-slate-900 p-3 rounded-lg select-all">{password}</p>
                      <button onClick={() => { setShowPasswordModal(false); setPassword(null); }} className="mt-3 text-slate-400 hover:text-white text-sm">Kapat</button>
                    </div>
                  )}
                </div>
              )}

              {/* Diğer şifre aksiyonları */}
              <div className="flex gap-2">
                <button onClick={handleResetLink} disabled={actionLoading === 'reset'} className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm disabled:opacity-50">
                  📧 Sıfırlama Linki Gönder
                </button>
                <button onClick={handleTempPassword} disabled={actionLoading === 'temp'} className="flex-1 bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg text-sm disabled:opacity-50">
                  🔄 Geçici Şifre Oluştur
                </button>
              </div>
              {tempPassword && (
                <div className="bg-purple-500/10 border border-purple-500/20 rounded-lg p-3">
                  <p className="text-purple-300 text-sm">Geçici Şifre (bir kez gösterilir):</p>
                  <p className="text-xl font-mono text-white select-all">{tempPassword}</p>
                </div>
              )}
            </div>
          </div>

          {/* Aksiyonlar */}
          <div className="bg-slate-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">İşlemler</h3>
            <button onClick={handleToggleActive} disabled={actionLoading === 'toggle'}
              className={`${user.is_active ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'} text-white px-6 py-2 rounded-lg text-sm font-medium disabled:opacity-50`}>
              {actionLoading === 'toggle' ? '...' : user.is_active ? '🚫 Pasife Al' : '✅ Aktif Et'}
            </button>
          </div>
        </div>

        {/* Sağ: Firmalar & Abonelik */}
        <div className="space-y-6">
          <div className="bg-slate-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">🏢 Firmalar</h3>
            {user.company_users?.length === 0 ? <p className="text-slate-400 text-sm">Firma yok</p> :
              user.company_users?.map((cu: any) => (
                <div key={cu.company.id} className="bg-slate-700 rounded-lg p-3 mb-2">
                  <p className="text-white font-medium">{cu.company.name}</p>
                  <p className="text-slate-400 text-xs">Rol: {cu.role} · Cari: {cu.company.accounts?.length || 0}</p>
                </div>
              ))
            }
          </div>
          <div className="bg-slate-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">📦 Abonelik</h3>
            {user.subscriptions?.length === 0 ? <p className="text-slate-400 text-sm">Abonelik yok</p> :
              user.subscriptions?.map((s: any) => (
                <div key={s.id} className="bg-slate-700 rounded-lg p-3 mb-2">
                  <p className="text-white font-medium">{s.plan?.name || 'Ücretsiz'}</p>
                  <p className="text-green-400 text-xs">Durum: {s.status}</p>
                </div>
              ))
            }
          </div>
        </div>
      </div>
    </div>
  );
}

