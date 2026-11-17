import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TicketStatus, TicketPriority, SenderType } from '@prisma/client';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  async createTicket(userId: string, data: {
    companyId?: string;
    subject: string;
    message: string;
    priority?: TicketPriority;
  }) {
    return this.prisma.$transaction(async (tx) => {
      const ticket = await tx.supportTicket.create({
        data: {
          user_id: userId,
          company_id: data.companyId || null,
          subject: data.subject,
          priority: data.priority || 'MEDIUM',
        },
      });

      await tx.supportMessage.create({
        data: {
          ticket_id: ticket.id,
          sender_id: userId,
          sender_type: 'USER',
          message: data.message,
        },
      });

      return ticket;
    });
  }

  async findAllTickets(userId: string, filters?: {
    status?: TicketStatus;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const where: any = { user_id: userId, deleted_at: null };
    if (filters?.status) where.status = filters.status;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: { updated_at: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          messages: { orderBy: { created_at: 'desc' }, take: 1 },
        },
      }),
      this.prisma.supportTicket.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findTicket(userId: string, id: string) {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: { id, user_id: userId, deleted_at: null },
      include: {
        messages: { orderBy: { created_at: 'asc' }, where: { deleted_at: null } },
      },
    });
    if (!ticket) throw new NotFoundException('Destek talebi bulunamadı');
    return ticket;
  }

  async addMessage(userId: string, ticketId: string, message: string, attachments?: string[]) {
    const ticket = await this.findTicket(userId, ticketId);
    if (ticket.status === 'CLOSED') {
      throw new BadRequestException('Kapatılmış talebe mesaj eklenemez');
    }

    const msg = await this.prisma.supportMessage.create({
      data: {
        ticket_id: ticketId,
        sender_id: userId,
        sender_type: 'USER',
        message,
        attachments: attachments || undefined,
      },
    });

    // Talebi tekrar açık duruma getir
    if (ticket.status === 'RESOLVED') {
      await this.prisma.supportTicket.update({
        where: { id: ticketId },
        data: { status: 'OPEN' },
      });
    }

    return msg;
  }

  async closeTicket(userId: string, id: string) {
    const ticket = await this.findTicket(userId, id);
    return this.prisma.supportTicket.update({
      where: { id },
      data: { status: 'CLOSED' },
    });
  }

  // Admin tarafından kullanılan metotlar
  async adminFindAll(filters?: {
    status?: TicketStatus;
    priority?: TicketPriority;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const where: any = { deleted_at: null };
    if (filters?.status) where.status = filters.status;
    if (filters?.priority) where.priority = filters.priority;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: [{ priority: 'desc' }, { updated_at: 'desc' }],
        skip: (page - 1) * limit,
        take: limit,
        include: {
          user: { select: { first_name: true, last_name: true, email: true } },
          messages: { orderBy: { created_at: 'desc' }, take: 1 },
        },
      }),
      this.prisma.supportTicket.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async adminReply(adminId: string, ticketId: string, message: string) {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: { id: ticketId, deleted_at: null },
    });
    if (!ticket) throw new NotFoundException('Destek talebi bulunamadı');

    const msg = await this.prisma.supportMessage.create({
      data: {
        ticket_id: ticketId,
        sender_id: adminId,
        sender_type: 'ADMIN',
        message,
      },
    });

    await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status: 'IN_PROGRESS' },
    });

    return msg;
  }

  async adminUpdateStatus(ticketId: string, status: TicketStatus) {
    return this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status },
    });
  }
}
