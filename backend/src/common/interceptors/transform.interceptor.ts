/**
 * Yanıt Dönüştürme Interceptor'ı
 * Tüm başarılı yanıtları { success: true, data: ..., meta: ... } formatına sarar.
 */
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  meta?: {
    total?: number;
    cursor?: string;
    hasMore?: boolean;
  };
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        // Eğer data zaten formatlanmışsa olduğu gibi döndür
        if (data && data.success !== undefined) {
          return data;
        }

        // Meta bilgisi varsa ayır
        if (data && data.data !== undefined && data.meta !== undefined) {
          return {
            success: true,
            data: data.data,
            meta: data.meta,
          };
        }

        return {
          success: true,
          data,
        };
      }),
    );
  }
}

