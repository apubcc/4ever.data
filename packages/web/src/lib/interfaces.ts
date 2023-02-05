export interface Dataset {
  id: number,
  created_at: string,
  name: string,
  desc: string,
  ipfs_hash: string,
  filecoin_hash: string,
  uploader: string,
  file_name: string,
  size: number,
  verified: boolean,
}
