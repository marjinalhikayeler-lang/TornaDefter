/**
 * Auth DTO'ları - Giriş ve Kayıt Veri Transfer Nesneleri
 */
import {
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  Matches,
  IsBoolean,
  IsNotEmpty,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ description: 'Ad', example: 'Ahmet' })
  @IsString()
  @IsNotEmpty({ message: 'Ad alanı zorunludur.' })
  first_name: string;

  @ApiProperty({ description: 'Soyad', example: 'Yılmaz' })
  @IsString()
  @IsNotEmpty({ message: 'Soyad alanı zorunludur.' })
  last_name: string;

  @ApiProperty({ description: 'E-posta adresi', example: 'ahmet@ornek.com' })
  @IsEmail({}, { message: 'Geçerli bir e-posta adresi girin.' })
  email: string;

  @ApiPropertyOptional({ description: 'Telefon numarası', example: '+905551234567' })
  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{10,13}$/, { message: 'Geçerli bir telefon numarası girin.' })
  phone?: string;

  @ApiProperty({ description: 'Şifre (en az 8 karakter, harf ve rakam içermeli)' })
  @IsString()
  @MinLength(8, { message: 'Şifre en az 8 karakter olmalıdır.' })
  @MaxLength(64, { message: 'Şifre en fazla 64 karakter olabilir.' })
  @Matches(/^(?=.*[A-Za-zÇçĞğİıÖöŞşÜü])(?=.*\d)/, {
    message: 'Şifre en az bir harf ve bir rakam içermelidir.',
  })
  password: string;

  @ApiProperty({ description: 'Şifre tekrar' })
  @IsString()
  password_confirm: string;

  @ApiProperty({ description: 'Kullanım koşulları onayı' })
  @IsBoolean()
  terms_accepted: boolean;
}

export class LoginDto {
  @ApiProperty({ description: 'E-posta veya telefon', example: 'ahmet@ornek.com' })
  @IsString()
  @IsNotEmpty({ message: 'E-posta veya telefon numarası gereklidir.' })
  identifier: string;

  @ApiProperty({ description: 'Şifre' })
  @IsString()
  @IsNotEmpty({ message: 'Şifre gereklidir.' })
  password: string;

  @ApiPropertyOptional({ description: 'Beni hatırla', default: false })
  @IsOptional()
  @IsBoolean()
  remember_me?: boolean;

  @ApiPropertyOptional({ description: 'Cihaz adı' })
  @IsOptional()
  @IsString()
  device_name?: string;

  @ApiPropertyOptional({ description: 'Cihaz türü (mobile/web/desktop)' })
  @IsOptional()
  @IsString()
  device_type?: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'Yenileme tokenı' })
  @IsString()
  @IsNotEmpty()
  refresh_token: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ description: 'E-posta adresi', example: 'ahmet@ornek.com' })
  @IsString()
  @IsNotEmpty({ message: 'E-posta veya telefon gereklidir.' })
  identifier: string;
}

export class ResetPasswordDto {
  @ApiProperty({ description: 'Sıfırlama tokenı/kodu' })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({ description: 'Yeni şifre' })
  @IsString()
  @MinLength(8, { message: 'Şifre en az 8 karakter olmalıdır.' })
  @Matches(/^(?=.*[A-Za-zÇçĞğİıÖöŞşÜü])(?=.*\d)/, {
    message: 'Şifre en az bir harf ve bir rakam içermelidir.',
  })
  new_password: string;
}

export class VerifyEmailDto {
  @ApiProperty({ description: 'Doğrulama tokenı' })
  @IsString()
  @IsNotEmpty()
  token: string;
}

export class VerifyPhoneDto {
  @ApiProperty({ description: '6 haneli doğrulama kodu' })
  @IsString()
  @MinLength(6)
  @MaxLength(6)
  code: string;
}

export class ChangePasswordDto {
  @ApiProperty({ description: 'Mevcut şifre' })
  @IsString()
  @IsNotEmpty()
  current_password: string;

  @ApiProperty({ description: 'Yeni şifre' })
  @IsString()
  @MinLength(8, { message: 'Şifre en az 8 karakter olmalıdır.' })
  @Matches(/^(?=.*[A-Za-zÇçĞğİıÖöŞşÜü])(?=.*\d)/, {
    message: 'Şifre en az bir harf ve bir rakam içermelidir.',
  })
  new_password: string;
}

