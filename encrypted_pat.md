{



  "key_id": "key_20260628104501_7d6219df",



  "cipher_suite": "AES-256-GCM",



  "nonce_b64": "RvV/eRaZAfMbqNCO",



  "ciphertext_tag_b64": "J/EFDkcwx0tSCLb8FrzifWYJCV8sae8IKAl/KXOWVizjVwbaaQ96rvlvaKi4SkeV+u57xjIhlq8=",



  "created_at": "2026-06-28T10:45:01.817375+00:00",



  "rotated_at": null



}



 

 

 

 

from pat_vault.src.github_pat_vault import GitHubPATVault



import requests



 

 

vault = GitHubPATVault("/home/user/.pat_vault/records.json")



 

 

# Plaintext exists in RAM only inside this block:



with vault.get_github_auth_header("user_github_pat") as headers:



    response = requests.get("https://api.github.com/user", headers=headers)



 

 

print("Authenticated Request Status:", response.status_code)