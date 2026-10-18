import { util } from "@kit.ArkTS";

// 时间戳转日期字符串
export function formatDate(timestamp: number): string {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = (date.getMonth() + 1);
  const day = date.getDate().toString().padStart(2, '0');
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  const seconds = date.getSeconds().toString().padStart(2, '0');

  return `${year}/${month}/${day} ${hours}:${minutes}:${seconds}`;
}

export function getStatusName(status: string): string {
  switch (status) {
    case 'ONLINE':
      return "在线";
    case 'OFFLINE':
      return "离线";
    case 'INACTIVE':
      return "未激活";
    case 'ACTIVE':
      return "已激活";
    default:
      return '未知';
  }
}

export function uint8ArrayToString(array: Uint8Array): string {
  let textDecoder = util.TextDecoder.create('utf-8');
  return textDecoder.decodeWithStream(array);
}

