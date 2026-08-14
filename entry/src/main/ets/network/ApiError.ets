/** Network/API failure categories retained for UI decisions. */
export enum ApiErrorKind {
  NETWORK = 'network',
  HTTP = 'http',
  UNAUTHORIZED = 'unauthorized',
  BUSINESS = 'business',
  PARSE = 'parse',
  CANCELLED = 'cancelled'
}

export class ApiError extends Error {
  readonly kind: ApiErrorKind;
  readonly httpStatus: number;
  readonly businessCode: number;
  readonly platformCode: number;

  constructor(kind: ApiErrorKind, message: string, httpStatus: number = 0, businessCode: number = 0,
    platformCode: number = 0) {
    super(message);
    this.name = 'ApiError';
    this.kind = kind;
    this.httpStatus = httpStatus;
    this.businessCode = businessCode;
    this.platformCode = platformCode;
  }
}

export function apiErrorMessage(error: Error): string {
  if (error instanceof ApiError) {
    return error.message;
  }
  return error.message.length > 0 ? error.message : '网络连接异常';
}
