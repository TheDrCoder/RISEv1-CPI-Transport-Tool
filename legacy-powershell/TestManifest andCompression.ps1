# Define Paths (Replace these with actual values before running)
$SourceExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\source_06c45eb4"
$MZipPath="C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs"
$TargetExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\target_307ac129"
$TenantURL = "https://swmx-test-lucfr9vh.it-cpi005.cfapps.eu20.hana.ondemand.com"
$AccessToken = "eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vc3dteC10ZXN0LWx1Y2ZyOXZoLmF1dGhlbnRpY2F0aW9uLmV1MjAuaGFuYS5vbmRlbWFuZC5jb20vdG9rZW5fa2V5cyIsImtpZCI6ImRlZmF1bHQtand0LWtleS0tNjI2NjgyMTA2IiwidHlwIjoiSldUIiwiamlkIjogIkZTRUtxQnRRbzE0S3FFTDV3TEpwQ2RkNG1nUjZMSUlGbEJnanNXR1VHa2M9In0.eyJqdGkiOiJjOGVhMjZkMDc1Y2U0MDk0ODEwZGM4Y2IyYjk3NGZmNCIsImV4dF9hdHRyIjp7ImVuaGFuY2VyIjoiWFNVQUEiLCJzdWJhY2NvdW50aWQiOiIyNzNlZWFjYi0xNmU0LTRlYzAtODgyYi1hODE0OTM1NjFjYTciLCJ6ZG4iOiJzd214LXRlc3QtbHVjZnI5dmgiLCJzZXJ2aWNlaW5zdGFuY2VpZCI6ImIzY2NmNmQwLWZkYTctNDI2OC04MTVmLWY2Yjk0ZDc1MTIxMCJ9LCJzdWIiOiJzYi1iM2NjZjZkMC1mZGE3LTQyNjgtODE1Zi1mNmI5NGQ3NTEyMTAhYjcwMTN8aXQhYjI1OSIsImF1dGhvcml0aWVzIjpbIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsUnVudGltZVBhcmFtZXRlci5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJTZW5zaXRpdmVEYXRhLlJlYWQiLCJpdCFiMjU5LldlYlRvb2xpbmdTZXR0aW5nc1Byb2R1Y3RQcm9maWxlcy5zYXZldGVuYW50Y29uZmlndXJhdGlvbiIsIml0IWIyNTkuVGVuYW50UGFydG5lckRpcmVjdG9yeS5yZWFkIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmV0cnkiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbENvbXBvbmVudC5SZXN0YXJ0IiwiaXQhYjI1OS5Xb3Jrc3BhY2VEZXNpZ25HdWlkZWxpbmVzLkNvbmZpZ3VyZSIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95Y29udGVudCIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuUmVhZCIsIml0IWIyNTkuRXh0ZXJuYWxMb2dnaW5nLkFjdGl2YXRlIiwiaXQhYjI1OS5Db21wYW55UHJvZmlsZS5SZWFkIiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5Xcml0ZSIsIml0IWIyNTkuV29ya3NwYWNlQXJ0aWZhY3RMb2Nrcy5EZWxldGUiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5Db25maWciLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9nLlN0YXR1c0NoYW5nZSIsIml0IWIyNTkuUm9sZXMuV3JpdGUiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5yZWFkUGF5bG9hZCIsIml0IWIyNTkuSW50ZWdyYXRpb25PcGVyYXRpb25TZXJ2ZXIucmVhZCIsIml0IWIyNTkuTm9kZU1hbmFnZXIucmVhZCIsIml0IWIyNTkuSW50ZWdyYXRpb25PcGVyYXRpb25TZXJ2ZXIubW9kaWZ5b3BlcmF0aW9uc2pvYnMiLCJ1YWEucmVzb3VyY2UiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5BY3RpdmF0ZSIsIml0IWIyNTkuRVNCTWVzc2FnZVN0b3JhZ2UuRGVsZXRlIiwiaXQhYjI1OS5NZXNzYWdlVXNhZ2VEYXNoYm9hcmQuUmVhZCIsIml0IWIyNTkuRXh0ZXJuYWxMb2dnaW5nQWN0aXZhdGlvbi5SZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclByb2ZpbGUuUmVhZCIsIml0IWIyNTkuTm9kZU1hbmFnZXIucmVhZHNlY3VyaXR5Y29udGVudCIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95Y3JlZGVudGlhbHMiLCJpdCFiMjU5LldlYlRvb2xpbmdDYXRhbG9nLkNyZWF0ZSIsIml0IWIyNTkuV2ViVG9vbGluZ0NhdGFsb2cuT3ZlcnZpZXdSZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5EZXRhaWxzUmVhZCIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJQcm9maWxlLldyaXRlIiwiaXQhYjI1OS5UZW5hbnRQYXJ0bmVyRGlyZWN0b3J5LndyaXRlIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLlB1Ymxpc2giLCJpdCFiMjU5LkRhdGFBcmNoaXZpbmcuUmVhZCIsIml0IWIyNTkuRGF0YUFyY2hpdmluZy5BY3RpdmF0ZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsQ29tcG9uZW50LlJlYWQiLCJpdCFiMjU5LkdlbmVyYXRpb25BbmRCdWlsZC5nZW5lcmF0aW9uYW5kYnVpbGRjb250ZW50IiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5SZWFkIiwiaXQhYjI1OS5lc2JtZXNzYWdlc3RvcmFnZS5yZWFkIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJTZW5zaXRpdmVEYXRhLldyaXRlIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmVhZCIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50LlB1Ymxpc2giLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyLlJlc3RhcnRDb21wb25lbnQiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MuRGVsZXRlIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLlJlYWQiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MuUmVhZCIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsUnVudGltZVBhcmFtZXRlci5SZWFkIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5SZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkY3JlZGVudGlhbHMiLCJpdCFiMjU5LldlYlRvb2xpbmcuRFNPREludGVncmF0aW9uIiwiaXQhYjI1OS5QSVByb3Zpc2lvbmluZy53cml0ZSIsIml0IWIyNTkuQ29kZWxpc3QuUmVhZCIsIml0IWIyNTkuV29ya3NwYWNlQXJ0aWZhY3RMb2Nrcy5SZWFkIiwiaXQhYjI1OS5Sb2xlcy5SZWFkIiwiaXQhYjI1OS5Db25maWd1cmF0aW9uU2VydmljZS5SdW50aW1lQnVzaW5lc3NQYXJhbWV0ZXJXcml0ZSIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLmRlbGV0ZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsT3BlcmF0aW9uQ29ja3BpdC5SZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5Eb3dubG9hZCIsIml0IWIyNTkuQ29tcGFueVByb2ZpbGUuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50LldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lckFncmVlbWVudC5SZWFkIiwiaXQhYjI1OS5EZWZhdWx0IiwiaXQhYjI1OS5XZWJUb29saW5nLkludGVncmF0aW9uRmxvd0NvbmZpZ3VyZSIsIml0IWIyNTkuR292ZXJuYW5jZS5Hb3Zlcm5hbmNlQ29tbWVudHNXcml0ZSIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95c2VjdXJpdHljb250ZW50IiwiaXQhYjI1OS5Hb3Zlcm5hbmNlLkdvdmVybmFuY2VDb21tZW50c1JlYWQiXSwic2NvcGUiOlsiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxSdW50aW1lUGFyYW1ldGVyLldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclNlbnNpdGl2ZURhdGEuUmVhZCIsIml0IWIyNTkuV2ViVG9vbGluZ1NldHRpbmdzUHJvZHVjdFByb2ZpbGVzLnNhdmV0ZW5hbnRjb25maWd1cmF0aW9uIiwiaXQhYjI1OS5UZW5hbnRQYXJ0bmVyRGlyZWN0b3J5LnJlYWQiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5yZXRyeSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsQ29tcG9uZW50LlJlc3RhcnQiLCJpdCFiMjU5LldvcmtzcGFjZURlc2lnbkd1aWRlbGluZXMuQ29uZmlndXJlIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5kZXBsb3ljb250ZW50IiwiaXQhYjI1OS5BZ3JlZW1lbnRUZW1wbGF0ZS5SZWFkIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmcuQWN0aXZhdGUiLCJpdCFiMjU5LkNvbXBhbnlQcm9maWxlLlJlYWQiLCJpdCFiMjU5LkNvbXBhbnlTZW5zaXRpdmVEYXRhLldyaXRlIiwiaXQhYjI1OS5Xb3Jrc3BhY2VBcnRpZmFjdExvY2tzLkRlbGV0ZSIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLkNvbmZpZyIsIml0IWIyNTkuTWVzc2FnZVByb2Nlc3NpbmdMb2cuU3RhdHVzQ2hhbmdlIiwiaXQhYjI1OS5Sb2xlcy5Xcml0ZSIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLnJlYWRQYXlsb2FkIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbk9wZXJhdGlvblNlcnZlci5yZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbk9wZXJhdGlvblNlcnZlci5tb2RpZnlvcGVyYXRpb25zam9icyIsInVhYS5yZXNvdXJjZSIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLkFjdGl2YXRlIiwiaXQhYjI1OS5FU0JNZXNzYWdlU3RvcmFnZS5EZWxldGUiLCJpdCFiMjU5Lk1lc3NhZ2VVc2FnZURhc2hib2FyZC5SZWFkIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmdBY3RpdmF0aW9uLlJlYWQiLCJpdCFiMjU5LldlYlRvb2xpbmdXb3Jrc3BhY2UuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyUHJvZmlsZS5SZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkc2VjdXJpdHljb250ZW50IiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5kZXBsb3ljcmVkZW50aWFscyIsIml0IWIyNTkuV2ViVG9vbGluZ0NhdGFsb2cuQ3JlYXRlIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5PdmVydmlld1JlYWQiLCJpdCFiMjU5LldlYlRvb2xpbmdDYXRhbG9nLkRldGFpbHNSZWFkIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclByb2ZpbGUuV3JpdGUiLCJpdCFiMjU5LlRlbmFudFBhcnRuZXJEaXJlY3Rvcnkud3JpdGUiLCJpdCFiMjU5LldlYlRvb2xpbmdXb3Jrc3BhY2UuUHVibGlzaCIsIml0IWIyNTkuRGF0YUFyY2hpdmluZy5SZWFkIiwiaXQhYjI1OS5EYXRhQXJjaGl2aW5nLkFjdGl2YXRlIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxDb21wb25lbnQuUmVhZCIsIml0IWIyNTkuR2VuZXJhdGlvbkFuZEJ1aWxkLmdlbmVyYXRpb25hbmRidWlsZGNvbnRlbnQiLCJpdCFiMjU5LkNvbXBhbnlTZW5zaXRpdmVEYXRhLlJlYWQiLCJpdCFiMjU5LmVzYm1lc3NhZ2VzdG9yYWdlLnJlYWQiLCJpdCFiMjU5LkFjY2Vzc1BvbGljaWVzLldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclNlbnNpdGl2ZURhdGEuV3JpdGUiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5yZWFkIiwiaXQhYjI1OS5BZ3JlZW1lbnRUZW1wbGF0ZS5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJBZ3JlZW1lbnQuUHVibGlzaCIsIml0IWIyNTkuTm9kZU1hbmFnZXIuUmVzdGFydENvbXBvbmVudCIsIml0IWIyNTkuTWVzc2FnZVByb2Nlc3NpbmdMb2Nrcy5EZWxldGUiLCJpdCFiMjU5LldlYlRvb2xpbmdXb3Jrc3BhY2UuUmVhZCIsIml0IWIyNTkuTWVzc2FnZVByb2Nlc3NpbmdMb2Nrcy5SZWFkIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxSdW50aW1lUGFyYW1ldGVyLlJlYWQiLCJpdCFiMjU5LkFjY2Vzc1BvbGljaWVzLlJlYWQiLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyLnJlYWRjcmVkZW50aWFscyIsIml0IWIyNTkuV2ViVG9vbGluZy5EU09ESW50ZWdyYXRpb24iLCJpdCFiMjU5LlBJUHJvdmlzaW9uaW5nLndyaXRlIiwiaXQhYjI1OS5Db2RlbGlzdC5SZWFkIiwiaXQhYjI1OS5Xb3Jrc3BhY2VBcnRpZmFjdExvY2tzLlJlYWQiLCJpdCFiMjU5LlJvbGVzLlJlYWQiLCJpdCFiMjU5LkNvbmZpZ3VyYXRpb25TZXJ2aWNlLlJ1bnRpbWVCdXNpbmVzc1BhcmFtZXRlcldyaXRlIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUuZGVsZXRlIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxPcGVyYXRpb25Db2NrcGl0LlJlYWQiLCJpdCFiMjU5LldlYlRvb2xpbmdDYXRhbG9nLkRvd25sb2FkIiwiaXQhYjI1OS5Db21wYW55UHJvZmlsZS5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJBZ3JlZW1lbnQuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50LlJlYWQiLCJpdCFiMjU5LkRlZmF1bHQiLCJpdCFiMjU5LldlYlRvb2xpbmcuSW50ZWdyYXRpb25GbG93Q29uZmlndXJlIiwiaXQhYjI1OS5Hb3Zlcm5hbmNlLkdvdmVybmFuY2VDb21tZW50c1dyaXRlIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5kZXBsb3lzZWN1cml0eWNvbnRlbnQiLCJpdCFiMjU5LkdvdmVybmFuY2UuR292ZXJuYW5jZUNvbW1lbnRzUmVhZCJdLCJjbGllbnRfaWQiOiJzYi1iM2NjZjZkMC1mZGE3LTQyNjgtODE1Zi1mNmI5NGQ3NTEyMTAhYjcwMTN8aXQhYjI1OSIsImNpZCI6InNiLWIzY2NmNmQwLWZkYTctNDI2OC04MTVmLWY2Yjk0ZDc1MTIxMCFiNzAxM3xpdCFiMjU5IiwiYXpwIjoic2ItYjNjY2Y2ZDAtZmRhNy00MjY4LTgxNWYtZjZiOTRkNzUxMjEwIWI3MDEzfGl0IWIyNTkiLCJncmFudF90eXBlIjoiY2xpZW50X2NyZWRlbnRpYWxzIiwicmV2X3NpZyI6Ijk1MWY2OTNlIiwiaWF0IjoxNzQwMjM2Mzg2LCJleHAiOjE3NDAyMzk5ODYsImlzcyI6Imh0dHBzOi8vc3dteC10ZXN0LWx1Y2ZyOXZoLmF1dGhlbnRpY2F0aW9uLmV1MjAuaGFuYS5vbmRlbWFuZC5jb20vb2F1dGgvdG9rZW4iLCJ6aWQiOiIyNzNlZWFjYi0xNmU0LTRlYzAtODgyYi1hODE0OTM1NjFjYTciLCJhdWQiOlsiaXQhYjI1OS5XZWJUb29saW5nIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbk9wZXJhdGlvblNlcnZlciIsIml0IWIyNTkuR292ZXJuYW5jZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJQcm9maWxlIiwiaXQhYjI1OS5Xb3Jrc3BhY2VEZXNpZ25HdWlkZWxpbmVzIiwiaXQhYjI1OS5FU0JNZXNzYWdlU3RvcmFnZSIsIml0IWIyNTkuQ29uZmlndXJhdGlvblNlcnZpY2UiLCJ1YWEiLCJpdCFiMjU5LlBJUHJvdmlzaW9uaW5nIiwiaXQhYjI1OSIsIml0IWIyNTkuQ29kZWxpc3QiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50IiwiaXQhYjI1OS5NZXNzYWdlUHJvY2Vzc2luZ0xvZyIsIml0IWIyNTkuTWVzc2FnZVVzYWdlRGFzaGJvYXJkIiwiaXQhYjI1OS5lc2JtZXNzYWdlc3RvcmFnZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsQ29tcG9uZW50IiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUiLCJpdCFiMjU5LkRhdGFBcmNoaXZpbmciLCJpdCFiMjU5LkNvbXBhbnlTZW5zaXRpdmVEYXRhIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZyIsIml0IWIyNTkuV2ViVG9vbGluZ1NldHRpbmdzUHJvZHVjdFByb2ZpbGVzIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmciLCJpdCFiMjU5LlRlbmFudFBhcnRuZXJEaXJlY3RvcnkiLCJpdCFiMjU5LlJvbGVzIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxSdW50aW1lUGFyYW1ldGVyIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclNlbnNpdGl2ZURhdGEiLCJpdCFiMjU5LldvcmtzcGFjZUFydGlmYWN0TG9ja3MiLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmdBY3RpdmF0aW9uIiwic2ItYjNjY2Y2ZDAtZmRhNy00MjY4LTgxNWYtZjZiOTRkNzUxMjEwIWI3MDEzfGl0IWIyNTkiLCJpdCFiMjU5LkdlbmVyYXRpb25BbmRCdWlsZCIsIml0IWIyNTkuQ29tcGFueVByb2ZpbGUiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbE9wZXJhdGlvbkNvY2twaXQiLCJpdCFiMjU5LkFncmVlbWVudFRlbXBsYXRlIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcyJdfQ.TipA3Lwib1-ZyPcW3GyRnjm02mBh3BePUBWNrgiHlJEP7OuqSIAo_q-azoqgNlo0he3qAonKhbfChez6Pc2sznBM5d_XTElTukjU8hbh4b7VHrreMm16ksvC_3n6WEnUqi6axcJQLjIEYN186CTdd20uZIhTYYrKWdvy5b1h9gS5G968m4thvPdlpGxm7zP-nPw9Wnehy2WJbbbBxYCo-7B4u8fa9w5lpfhW-Ik6kv7GpqDimlrEjsOEzQGBCIMuOUlxsw9wkloRP4wCckAsnODvwNGZ3dBNgFjuarp2kRhlDeqNeeJsOQ7goy1fjMA0Iw6p74NE6Psgw6aTtQRM8Q"

# Expected file paths
$SourceManifestPath = "$SourceExtractPath\META-INF\MANIFEST.MF"
$TargetManifestPath = "$TargetExtractPath\META-INF\MANIFEST.MF"
$OutputZipPath = "$MZipPath\Modified_Artifact.zip"
$OutputManifest = $SourceManifestPath

# Ensure files exist before proceeding
if (-not (Test-Path $SourceManifestPath)) { Write-Host "❌ Source Manifest Not Found!"; exit }
if (-not (Test-Path $TargetManifestPath)) { Write-Host "❌ Target Manifest Not Found!"; exit }


### 📌 Function to Read Manifest File (Preserving Multi-Line Formatting)
function Read-ManifestFile {
    param ([string]$filePath)
    $manifestLines = Get-Content -Path $filePath
    $manifestContent = ""

    foreach ($line in $manifestLines) {
        if ($line -match "^\s") { $manifestContent += "`n" + $line }  # Preserve leading spaces for continuation lines
        else { $manifestContent += "`n" + $line }
    }
    return $manifestContent.Trim()
}

### 📌 Function to Extract Multi-Line Values Without Modifying Format
function Extract-ManifestValues {
    param ([string]$content, [array]$keys)
    $values = @{}

    foreach ($key in $keys) {
        $regex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"
        $match = [regex]::Match($content, $regex)
        if ($match.Success) {
            $values[$key] = $match.Value  # Preserve full multi-line format
        }
    }
    return $values
}

### 📌 Function to Replace Multi-Line Values While Keeping Original Formatting
function Replace-ManifestValues {
    param ([string]$sourceContent, [hashtable]$targetValues, [array]$keys)
    
    foreach ($key in $keys) {
        if ($targetValues.ContainsKey($key) -and $targetValues[$key]) {
            $sourceRegex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"

            # Debugging: Show exact matches before replacement
            $matches = [regex]::Match($sourceContent, $sourceRegex)
            Write-Host "`n🔎 Matching Source Manifest for Key: $key"
            Write-Host "--------------------------------------"
            Write-Host "🔹 Matched Value (Source): '$($matches.Value)'"
            Write-Host "🔹 Replacing With (Target): '$($targetValues[$key])'"
            Write-Host "--------------------------------------`n"

            # Perform precise replacement while keeping multi-line structure
            $sourceContent = [regex]::Replace($sourceContent, $sourceRegex, $targetValues[$key])
        }
    }
    return $sourceContent
}

########################
# Function to remove BOM and preserve line breaks
function Remove-BOM {
    param ([string]$filePath)

    # Read the file as bytes to check for BOM
    $bytes = [System.IO.File]::ReadAllBytes($filePath)

    # Check for UTF-8 BOM (EF BB BF) and remove it if present
    if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $bytes = $bytes[3..($bytes.Length - 1)]  # Remove the first 3 BOM bytes
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        Write-Host "✅ BOM removed from the Manifest file."
    } else {
        Write-Host "✅ No BOM detected, file is already correct."
    }
}

### 📌 Function to Process Manifest Replacement (Everything in One Function)
function Process-ManifestReplacement {
    param (
        [string]$sourceFile,
        [string]$targetFile,
        [string]$outputFile,
        [array]$keys
    )

    $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")
    # Read Source and Target Manifest Files
    $sourceContent = Read-ManifestFile -filePath $sourceFile
    $targetContent = Read-ManifestFile -filePath $targetFile

    # Extract Values from Target Manifest
    $TargetValues = Extract-ManifestValues -content $targetContent -keys $keys

    # Debug: Print Extracted Target Values
    Write-Host "`n📝 Extracted Target Values:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $TargetValues.Keys) { Write-Host "🔹 $key = '$($TargetValues[$key])'" }
    Write-Host "----------------------------------------------------`n"

    # Replace Values in the Source Manifest
    $ModifiedContent = Replace-ManifestValues -sourceContent $sourceContent -targetValues $TargetValues -keys $keys

    # Save the Modified Manifest File
    $ModifiedContent | Set-Content -Path $outputFile -Encoding UTF8
    Write-Host "✅ Manifest file has been successfully modified and saved as $outputFile"

    # Call function to clean up BOM
Remove-BOM -filePath $outputManifest

    # Debug: Verify Final Values After Replacement
    $NewContent = Read-ManifestFile -filePath $outputFile
    $NewValues = Extract-ManifestValues -content $NewContent -keys $keys

    Write-Host "`n📝 New Manifest Values After Replacement:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $NewValues.Keys) { Write-Host "🔹 $key = '$($NewValues[$key])'" }
    Write-Host "----------------------------------------------------`n"
}

### Preserve Folder Structure While Creating ZIP
function Create-Zip {
    param ([string]$ExtractedPath, [string]$ZipPath)

    Write-Host "📦 Creating ZIP Archive..."

    if (Test-Path $ZipPath) { Remove-Item -Path $ZipPath -Force }

    # Load required .NET assembly
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create ZIP file
    $zipStream = [System.IO.File]::Create($ZipPath)
    $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

    # Add files while preserving directory structure
    Get-ChildItem -Path $ExtractedPath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($ExtractedPath.Length + 1) -replace "\\", "/"
        $entry = $zipArchive.CreateEntry($relativePath)
        $stream = $entry.Open()
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }

    # Close ZIP
    $zipArchive.Dispose()
    $zipStream.Close()

    Write-Host "✅ ZIP Created Successfully: $ZipPath"
}

#  Function to Convert ZIP to Base64
function Convert-ZipToBase64 {
    param ([string]$ZipPath)

    Write-Host "🔄 Converting ZIP to Base64..."
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    $base64String = [Convert]::ToBase64String($bytes)
    
    # Save Base64 to file for easy copy-paste
    $base64FilePath = "$ZipPath.base64.txt"
    $base64String | Set-Content -Path $base64FilePath -Encoding UTF8

    Write-Host "✅ Base64 Conversion Completed! Output saved to: $base64FilePath"
    return $base64String
}

#  Run Steps
Write-Host "🔍 Running Local Test..."

# Step 1: Modify Manifest

### 🚀 **Execute the Function**
Process-ManifestReplacement -sourceFile $SourceManifestPath -targetFile $TargetManifestPath -outputFile $OutputManifest

# Step 2: Create ZIP Archive
Create-Zip -ExtractedPath $SourceExtractPath -ZipPath $OutputZipPath

# Step 3: Convert ZIP to Base64
$base64Zip = Convert-ZipToBase64 -ZipPath $OutputZipPath

# Step 4: Print Base64 Output
Write-Host "📋 Base64 ZIP Content (Copy this for Postman):"
#Write-Output $base64Zip

Write-Host "🎯 Testing Completed! Check the ZIP and Base64 output."
