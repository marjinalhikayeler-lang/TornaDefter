/**
 * Veritabanı Seed Dosyası
 * İlk çalıştırmada temel verileri oluşturur:
 * - Planlar (Ücretsiz, Standart, Pro)
 * - Admin hesabı
 */
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'tornadefter_default_key_32chars!';

function encryptPassword(password: string): string {
  const iv = crypto.randomBytes(16);
  const key = Buffer.from(ENCRYPTION_KEY.padEnd(32, '0').slice(0, 32));
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(password);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Veritabanı seed başlatılıyor...');

  // ============ PLANLAR ============
  const plans = [
    {
      name: 'Ücretsiz',
      slug: 'free',
      max_accounts: 20,
      max_users: 1,
      max_companies: 1,
      backup_frequency: 'DAILY',
      storage_limit: 100, // MB
      price_monthly: 0,
      price_yearly: 0,
      trial_days: 0,
      sort_order: 1,
    },
    {
      name: 'Standart',
      slug: 'standard',
      max_accounts: 200,
      max_users: 3,
      max_companies: 2,
      backup_frequency: 'DAILY',
      storage_limit: 1000,
      price_monthly: 9900, // 99 TL
      price_yearly: 99900, // 999 TL
      trial_days: 14,
      sort_order: 2,
    },
    {
      name: 'Pro',
      slug: 'pro',
      max_accounts: 999999,
      max_users: 10,
      max_companies: 5,
      backup_frequency: 'HOURLY',
      storage_limit: 10000,
      price_monthly: 19900, // 199 TL
      price_yearly: 199900, // 1999 TL
      trial_days: 14,
      sort_order: 3,
    },
  ];

  for (const plan of plans) {
    await prisma.plan.upsert({
      where: { slug: plan.slug },
      update: plan,
      create: plan,
    });
  }
  console.log('✅ Planlar oluşturuldu');

  // ============ ADMIN HESABI ============
  const adminPassword = await bcrypt.hash('Admin123!', 12);
  await prisma.admin.upsert({
    where: { email: 'admin@tornadefter.com' },
    update: {},
    create: {
      email: 'admin@tornadefter.com',
      password_hash: adminPassword,
      first_name: 'Sistem',
      last_name: 'Yöneticisi',
      role: 'SUPER_ADMIN',
      is_active: true,
    },
  });
  console.log('✅ Admin hesabı oluşturuldu (admin@tornadefter.com / Admin123!)');

  // ============ TEST KULLANICISI ============
  const testPassword = await bcrypt.hash('Test1234', 12);
  const testPasswordEncrypted = encryptPassword('Test1234');
  const testUser = await prisma.user.upsert({
    where: { email: 'test@tornadefter.com' },
    update: {
      password_encrypted: testPasswordEncrypted,
    },
    create: {
      email: 'test@tornadefter.com',
      phone: '+905551234567',
      password_hash: testPassword,
      password_encrypted: testPasswordEncrypted,
      first_name: 'Test',
      last_name: 'Kullanıcı',
      email_verified: true,
      phone_verified: true,
    },
  });

  // Test firması
  const freePlan = await prisma.plan.findUnique({ where: { slug: 'free' } });
  if (freePlan) {
    await prisma.subscription.upsert({
      where: { id: testUser.id }, // dummy - will create
      update: {},
      create: {
        user_id: testUser.id,
        plan_id: freePlan.id,
        status: 'ACTIVE',
      },
    });
  }

  const testCompany = await prisma.company.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      owner_id: testUser.id,
      name: 'Test İşletmesi',
      tax_office: 'Ankara',
      tax_number: '1234567890',
      city: 'Ankara',
      district: 'Çankaya',
      phone: '+903121234567',
    },
  });

  await prisma.companyUser.upsert({
    where: {
      company_id_user_id: {
        company_id: testCompany.id,
        user_id: testUser.id,
      },
    },
    update: {},
    create: {
      company_id: testCompany.id,
      user_id: testUser.id,
      role: 'OWNER',
    },
  });

  // Ana Kasa
  await prisma.cashAccount.upsert({
    where: { id: '00000000-0000-0000-0000-000000000010' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000010',
      company_id: testCompany.id,
      name: 'Ana Kasa',
      currency: 'TRY',
      opening_balance: 500000, // 5.000 TL
      current_balance: 500000,
    },
  });

  // Test Cari Hesapları (OkLif tarzı)
  const testAccounts = [
    { code: 'M-0001', title: 'ALFAMED ELEKTRONİK SAN. VE TİC. LTD. ŞTİ.', account_type: 'CUSTOMER' as const, opening_balance: 2100000 },
    { code: 'T-0001', title: 'C.D. MEDİKAL SAN. VE TİC. LTD. ŞTİ.', account_type: 'SUPPLIER' as const, opening_balance: 0 },
    { code: 'M-0002', title: 'YILMAZ OTOMOTİV', account_type: 'CUSTOMER' as const, opening_balance: 0 },
    { code: 'M-0003', title: 'KAYA İNŞAAT', account_type: 'CUSTOMER' as const, opening_balance: 0 },
    { code: 'P-0001', title: 'Ahmet Yılmaz', account_type: 'PERSONNEL' as const, opening_balance: 0 },
  ];

  for (const acc of testAccounts) {
    await prisma.account.upsert({
      where: { company_id_code: { company_id: testCompany.id, code: acc.code } },
      update: {},
      create: {
        company_id: testCompany.id,
        ...acc,
        opening_balance_direction: 'DEBIT',
        currency: 'TRY',
      },
    });
  }
  console.log('✅ Test verileri oluşturuldu');

  console.log('🎉 Seed tamamlandı!');
}

main()
  .catch((e) => {
    console.error('Seed hatası:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

