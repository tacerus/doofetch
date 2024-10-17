Script to download the latest Kiwi image built in OBS.
Requires a repository with `Repotype: staticlinks`.

`$URL` should be set to the unversioned link on the download server.

Upon execution, it will:

1. query `$URL` to find the `Location` header pointing to the latest versioned file
2. compare if the latest versioned file name matches the file `$TARGETLINK` is pointing to
3. if it matches, exit, otherwise continue
4. download the latest versioned file, along with the checksum and the checksum signature
5. verify the checksum signature (public key must be imported in the default keychain of the calling user prior)
6. verify the checksum
7. if both verifications succeed, point `$TARGETLINK` to the new versioned file
