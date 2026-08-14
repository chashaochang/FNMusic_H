import { ApiError, ApiErrorKind } from './ApiError';

export interface ApiEnvelopeWire<T> {
  code?: number | string;
  msg?: string;
  data?: T;
}

export interface EmptyResponseData {
}

export class ApiEnvelope<T> {
  code: number = -1;
  message: string = '';
  data?: T;
}

/** Strictly parses the public `{code,msg,data}` contract. */
export function parseApiEnvelope<T>(text: string, requireData: boolean = true): ApiEnvelope<T> {
  let raw: ApiEnvelopeWire<T>;
  try {
    raw = JSON.parse(text) as ApiEnvelopeWire<T>;
  } catch (_) {
    throw new ApiError(ApiErrorKind.PARSE, '服务器返回了无法解析的数据');
  }
  const parsedCode = typeof raw.code === 'number' ? raw.code : Number(raw.code);
  if (!Number.isFinite(parsedCode)) {
    throw new ApiError(ApiErrorKind.PARSE, '服务器响应缺少业务状态码');
  }
  const code = Math.floor(parsedCode);
  if (code !== 0) {
    const message = (raw.msg ?? '').trim().length > 0 ? `${raw.msg}` : `服务端业务错误 ${code}`;
    const kind = code === 401 || message.toUpperCase().indexOf('INVALID TOKEN') >= 0 ?
      ApiErrorKind.UNAUTHORIZED : ApiErrorKind.BUSINESS;
    throw new ApiError(kind, message, 0, code);
  }
  if (requireData && raw.data === undefined) {
    throw new ApiError(ApiErrorKind.PARSE, '服务器响应缺少 data 字段');
  }
  const result = new ApiEnvelope<T>();
  result.code = code;
  result.message = raw.msg ?? '';
  result.data = raw.data;
  return result;
}
