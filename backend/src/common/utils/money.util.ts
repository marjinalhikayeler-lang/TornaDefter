/**
 * Para Birimi Yardımcı Fonksiyonları
 * Tüm tutarlar kuruş cinsinden integer olarak saklanır.
 * Float/double KULLANILMAZ - kuruş hassasiyeti korunur.
 */

/**
 * Kuruş tutarını Türk Lirası formatında gösterir.
 * @example formatMoney(1234567) => "12.345,67 TL"
 */
export function formatMoney(amountInKurus: number, currency = 'TRY'): string {
  const lira = Math.floor(Math.abs(amountInKurus) / 100);
  const kurus = Math.abs(amountInKurus) % 100;
  const sign = amountInKurus < 0 ? '-' : '';

  const formattedLira = lira.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  const formattedKurus = kurus.toString().padStart(2, '0');

  const currencySymbol = currency === 'TRY' ? 'TL' : currency;
  return `${sign}${formattedLira},${formattedKurus} ${currencySymbol}`;
}

/**
 * Kullanıcının girdiği TL tutarını kuruşa çevirir.
 * @example parseMoney("12.345,67") => 1234567
 * @example parseMoney("100") => 10000
 * @example parseMoney("100,5") => 10050
 */
export function parseMoney(displayAmount: string): number {
  if (!displayAmount) return 0;

  // Boşlukları ve para birimi sembolünü temizle
  let cleaned = displayAmount.replace(/\s/g, '').replace(/TL/gi, '').trim();

  // Negatif kontrolü
  const isNegative = cleaned.startsWith('-');
  if (isNegative) cleaned = cleaned.substring(1);

  // Nokta binlik ayraçlarını kaldır, virgülü noktaya çevir
  cleaned = cleaned.replace(/\./g, '').replace(',', '.');

  const parsed = parseFloat(cleaned);
  if (isNaN(parsed)) return 0;

  // Kuruşa çevir (100 ile çarp ve tam sayıya yuvarla)
  const kurus = Math.round(parsed * 100);
  return isNegative ? -kurus : kurus;
}

/**
 * Birden fazla kuruş tutarını güvenle toplar.
 */
export function addMoney(...amounts: number[]): number {
  return amounts.reduce((sum, amount) => sum + amount, 0);
}

/**
 * İki kuruş tutarının farkını hesaplar.
 */
export function subtractMoney(a: number, b: number): number {
  return a - b;
}

/**
 * Kuruş tutarını Lira'ya çevirir (sadece görüntüleme için).
 */
export function kurusToLira(amountInKurus: number): number {
  return amountInKurus / 100;
}

/**
 * Lira tutarını kuruşa çevirir.
 */
export function liraToKurus(amountInLira: number): number {
  return Math.round(amountInLira * 100);
}

