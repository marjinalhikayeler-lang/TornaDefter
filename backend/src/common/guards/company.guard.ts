/**
 * Firma Erişim Guard'ı
 * Kullanıcının istekte belirtilen firmaya erişim yetkisi olup olmadığını kontrol eder.
 * Tüm firma-bazlı endpoint'lerde kullanılır.
 */
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CompanyGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Oturum açmanız gerekiyor.');
    }

    // company_id header veya params'dan alınır
    const companyId =
      request.headers['x-company-id'] ||
      request.params.companyId ||
      request.body?.company_id;

    if (!companyId) {
      throw new BadRequestException('Firma bilgisi gereklidir. X-Company-Id header veya companyId parametresi gönderin.');
    }

    // Kullanıcının bu firmaya üyeliğini kontrol et
    const membership = await this.prisma.companyUser.findUnique({
      where: {
        company_id_user_id: {
          company_id: companyId,
          user_id: user.id,
        },
      },
    });

    if (!membership) {
      throw new ForbiddenException('Bu firmaya erişim yetkiniz bulunmuyor.');
    }

    // İstek nesnesine firma bilgisi ve rol ekle
    request.companyId = companyId;
    request.companyRole = membership.role;
    request.companyPermissions = membership.custom_permissions;

    return true;
  }
}

