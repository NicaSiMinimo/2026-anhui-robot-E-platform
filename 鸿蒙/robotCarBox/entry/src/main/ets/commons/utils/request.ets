/**
 * Http 请求工具，基于 axios 封装
 */
import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from '@ohos/axios'

export const baseURL = 'http://192.168.4.1/'

export const instance = axios.create({
  baseURL,
  timeout: 100000
})

// 响应拦截器
instance.interceptors.response.use((res: AxiosResponse) => {
  if (res.data.code === 10000) {
    console.debug('Req Success', JSON.stringify(res.data.data))
    return res.data.data
  }
  console.error('Req Error', JSON.stringify(res.data))
  return Promise.reject(res.data)
}, (err: AxiosError) => {
  console.error('Req Error', JSON.stringify(err))
  return Promise.reject(err)
})

class Http {
  // Get 请求可以省略第二个泛型，因为axios默认是any任何值可传
  request<ResponseData, RequestData = Object>(config: AxiosRequestConfig<RequestData>) {
    return instance<null, ResponseData, RequestData>(config)
  }
}

export const http = new Http()