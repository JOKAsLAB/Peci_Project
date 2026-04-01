import { AxiosError } from 'axios'
import { describe, expect, it } from 'vitest'

import { getApiErrorMessage, http } from '../../../../admin_docente/src/services/http'

describe('http client configuration', () => {
  it('enables credentials by default for cookie-based sessions', () => {
    expect(http.defaults.withCredentials).toBe(true)
    expect(http.defaults.baseURL).toBeTruthy()
  })

  it('sets JSON content type by default', () => {
    const headers = http.defaults.headers
    const contentType = headers['Content-Type'] ?? headers?.common?.['Content-Type']

    expect(contentType).toBe('application/json')
  })
})

describe('getApiErrorMessage', () => {
  it('returns API detail when it is a string', () => {
    const error = new AxiosError('request failed')
    error.response = {
      data: { detail: 'Invalid credentials' },
      status: 401,
      statusText: 'Unauthorized',
      headers: {},
      config: { headers: {} },
    }

    expect(getApiErrorMessage(error, 'fallback')).toBe('Invalid credentials')
  })

  it('aggregates validation detail arrays in stable order', () => {
    const detail = Array.from({ length: 50 }, (_, idx) => ({ msg: `validation-${idx + 1}` }))
    const error = new AxiosError('validation failed')
    error.response = {
      data: { detail },
      status: 422,
      statusText: 'Unprocessable Entity',
      headers: {},
      config: { headers: {} },
    }

    const message = getApiErrorMessage(error, 'fallback')
    expect(message).toContain('validation-1')
    expect(message).toContain('validation-50')
  })

  it('falls back when payload has no usable detail', () => {
    const error = new AxiosError('network unavailable')
    error.response = {
      data: { detail: [{ code: 'x' }] },
      status: 500,
      statusText: 'Server Error',
      headers: {},
      config: { headers: {} },
    }

    expect(getApiErrorMessage(error, 'fallback')).toBe('network unavailable')
    expect(getApiErrorMessage({ some: 'unknown' }, 'fallback')).toBe('fallback')
  })
})
