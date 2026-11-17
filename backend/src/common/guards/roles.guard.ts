/**
 * Rol Guard'ı
 * @Roles() dekoratörü ile belirtilen rollere sahip kullanıcılara erişim sağlar.
 */
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { CompanyRole } from '@prisma/client';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<CompanyRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const userRole = request.companyRole;

    if (!userRole) {
      throw new ForbiddenException('Firma rolünüz belirlenemedi.');
    }

    if (!requiredRoles.includes(userRole)) {
      throw new ForbiddenException(
        'Bu işlem için yetkiniz bulunmuyor. Gerekli rol: ' +
          requiredRoles.join(', '),
      );
    }

    return true;
  }
}

