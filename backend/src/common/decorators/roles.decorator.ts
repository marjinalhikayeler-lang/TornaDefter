/**
 * @Roles() Dekoratörü
 * Endpoint'lere rol tabanlı erişim kısıtlaması ekler.
 */
import { SetMetadata } from '@nestjs/common';
import { CompanyRole } from '@prisma/client';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: CompanyRole[]) => SetMetadata(ROLES_KEY, roles);

