import type { ReactNode } from 'react';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  color: 'blue' | 'green' | 'purple' | 'orange' | 'pink';
}

const colorClasses = {
  blue: {
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/20',
    icon: 'text-blue-400 bg-blue-500/20',
    value: 'text-blue-400',
  },
  green: {
    bg: 'bg-emerald-500/10',
    border: 'border-emerald-500/20',
    icon: 'text-emerald-400 bg-emerald-500/20',
    value: 'text-emerald-400',
  },
  purple: {
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/20',
    icon: 'text-purple-400 bg-purple-500/20',
    value: 'text-purple-400',
  },
  orange: {
    bg: 'bg-orange-500/10',
    border: 'border-orange-500/20',
    icon: 'text-orange-400 bg-orange-500/20',
    value: 'text-orange-400',
  },
  pink: {
    bg: 'bg-pink-500/10',
    border: 'border-pink-500/20',
    icon: 'text-pink-400 bg-pink-500/20',
    value: 'text-pink-400',
  },
};

export default function StatsCard({ title, value, icon, color }: StatsCardProps) {
  const classes = colorClasses[color];

  return (
    <div className={`${classes.bg} ${classes.border} border rounded-xl p-6 transition-all duration-200 hover:scale-[1.02]`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-slate-400 mb-1">{title}</p>
          <p className={`text-3xl font-bold ${classes.value}`}>{value}</p>
        </div>
        <div className={`${classes.icon} p-3 rounded-xl`}>
          {icon}
        </div>
      </div>
    </div>
  );
}
