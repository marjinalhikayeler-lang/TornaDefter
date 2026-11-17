import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CategoryType } from '@prisma/client';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, data: {
    name: string;
    type: CategoryType;
    parentId?: string;
  }) {
    return this.prisma.category.create({
      data: {
        company_id: companyId,
        name: data.name,
        type: data.type,
        parent_id: data.parentId || null,
      },
    });
  }

  async findAll(companyId: string, type?: CategoryType) {
    const where: any = { company_id: companyId, deleted_at: null };
    if (type) where.type = type;

    const categories = await this.prisma.category.findMany({
      where,
      include: { children: { where: { deleted_at: null } } },
      orderBy: { name: 'asc' },
    });

    // Hiyerarşik yapı: sadece üst kategorileri döndür, alt kategoriler iç içe gelir
    const roots = categories.filter(c => !c.parent_id);
    return roots;
  }

  async findOne(companyId: string, id: string) {
    const category = await this.prisma.category.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
      include: { children: { where: { deleted_at: null } } },
    });
    if (!category) throw new NotFoundException('Kategori bulunamadı');
    return category;
  }

  async update(companyId: string, id: string, data: { name?: string; parentId?: string }) {
    await this.findOne(companyId, id);
    return this.prisma.category.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.parentId !== undefined && { parent_id: data.parentId }),
      },
    });
  }

  async remove(companyId: string, id: string) {
    await this.findOne(companyId, id);
    // Alt kategorileri de sil
    await this.prisma.category.updateMany({
      where: { parent_id: id, company_id: companyId },
      data: { deleted_at: new Date() },
    });
    return this.prisma.category.update({ where: { id }, data: { deleted_at: new Date() } });
  }

  async getTree(companyId: string, type?: CategoryType) {
    const all = await this.prisma.category.findMany({
      where: { company_id: companyId, deleted_at: null, ...(type ? { type } : {}) },
      orderBy: { name: 'asc' },
    });

    const buildTree = (parentId: string | null): any[] => {
      return all
        .filter(c => c.parent_id === parentId)
        .map(c => ({ ...c, children: buildTree(c.id) }));
    };

    return buildTree(null);
  }
}
