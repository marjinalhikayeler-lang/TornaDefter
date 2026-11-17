import { useState, useEffect } from 'react';
import { adminApi } from '../api/admin';
import { useAuth } from '../context/AuthContext';

const statusColors: Record<string, string> = {
  OPEN: 'bg-yellow-500/20 text-yellow-400',
  IN_PROGRESS: 'bg-blue-500/20 text-blue-400',
  RESOLVED: 'bg-green-500/20 text-green-400',
  CLOSED: 'bg-slate-500/20 text-slate-400',
};
const statusLabels: Record<string, string> = { OPEN: 'Açık', IN_PROGRESS: 'İşlemde', RESOLVED: 'Çözüldü', CLOSED: 'Kapatıldı' };
const priorityColors: Record<string, string> = { LOW: 'text-slate-400', MEDIUM: 'text-yellow-400', HIGH: 'text-red-400' };
const priorityLabels: Record<string, string> = { LOW: 'Düşük', MEDIUM: 'Orta', HIGH: 'Yüksek' };

export default function SupportPage() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<any>(null);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);
  const { adminId } = useAuth();

  useEffect(() => {
    adminApi.getSupportTickets({}).then(r => { setTickets(r.data.items || []); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  const handleReply = async () => {
    if (!reply.trim() || !selected || !adminId) return;
    setSending(true);
    try {
      await adminApi.replySupportTicket(adminId, selected.id, reply);
      setReply('');
      alert('Yanıt gönderildi');
    } catch {}
    setSending(false);
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-white mb-6">Destek Talepleri</h1>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Liste */}
        <div className="bg-slate-800 rounded-xl overflow-hidden">
          {loading ? <p className="text-slate-400 text-center py-8">Yükleniyor...</p> :
          tickets.length === 0 ? <p className="text-slate-400 text-center py-8">Talep yok</p> :
          tickets.map(t => (
            <div key={t.id} onClick={() => setSelected(t)}
              className={`p-4 border-b border-slate-700 cursor-pointer hover:bg-slate-700/50 ${selected?.id === t.id ? 'bg-slate-700' : ''}`}>
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-white font-medium">{t.subject}</p>
                  <p className="text-slate-400 text-sm">{t.user?.first_name} {t.user?.last_name} · {t.user?.email}</p>
                </div>
                <div className="text-right">
                  <span className={`px-2 py-1 rounded-full text-xs ${statusColors[t.status] || ''}`}>{statusLabels[t.status] || t.status}</span>
                  <p className={`text-xs mt-1 ${priorityColors[t.priority] || ''}`}>{priorityLabels[t.priority] || t.priority}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
        {/* Detay */}
        <div className="bg-slate-800 rounded-xl p-6">
          {!selected ? <p className="text-slate-400 text-center py-8">Bir talep seçin</p> : (
            <div>
              <h3 className="text-lg font-semibold text-white mb-2">{selected.subject}</h3>
              <div className="flex gap-2 mb-4">
                <span className={`px-2 py-1 rounded-full text-xs ${statusColors[selected.status]}`}>{statusLabels[selected.status]}</span>
                <span className={`text-xs ${priorityColors[selected.priority]}`}>{priorityLabels[selected.priority]}</span>
              </div>
              <div className="space-y-3 max-h-80 overflow-y-auto mb-4">
                {selected.messages?.map((m: any, i: number) => (
                  <div key={i} className={`p-3 rounded-lg ${m.sender_type === 'ADMIN' ? 'bg-blue-600/20 ml-4' : 'bg-slate-700 mr-4'}`}>
                    <p className="text-xs text-slate-400 mb-1">{m.sender_type === 'ADMIN' ? '👤 Admin' : '👤 Kullanıcı'}</p>
                    <p className="text-white text-sm">{m.message}</p>
                  </div>
                )) || <p className="text-slate-400 text-sm">Mesaj yok</p>}
              </div>
              <div className="flex gap-2">
                <input value={reply} onChange={e => setReply(e.target.value)} placeholder="Yanıtınızı yazın..."
                  className="flex-1 bg-slate-700 text-white rounded-lg px-4 py-2 outline-none focus:ring-2 focus:ring-blue-500" />
                <button onClick={handleReply} disabled={sending} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg disabled:opacity-50">
                  {sending ? '...' : 'Gönder'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

