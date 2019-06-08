"""
Example interaction with Lightning (LND) gRPC

https://dev.lightning.community/guides/python-grpc/

https://api.lightning.community/?python


Assumes that lnd.proto has already been compiled to obtain rpc_pb2.py and rpc_pb2_grpc.py 
"""

import rpc_pb2 as ln
import rpc_pb2_grpc as lnrpc
import grpc
import os
import codecs

# Due to updated ECDSA generated tls.cert we need to let gprc know that
# we need to use that cipher suite otherwise there will be a handhsake
# error when we communicate with the lnd rpc server.
os.environ["GRPC_SSL_CIPHER_SUITES"] = 'HIGH+ECDSA'

# Lnd cert is at ~/.lnd/tls.cert on Linux and
# ~/Library/Application Support/Lnd/tls.cert on Mac
cert = open(os.path.expanduser('~/.lnd/tls.cert'), 'rb').read()

# build ssl credentials using the cert
cert_creds = grpc.ssl_channel_credentials(cert)

#illustrating for alice (port 10001)
with open(os.path.expanduser('~/snap/go/dev/alice/data/chain/bitcoin/simnet/admin.macaroon'), 'rb') as f:
    macaroon_bytes = f.read()
    macaroon = codecs.encode(macaroon_bytes, 'hex')

def metadata_callback(context, callback):
    # for more info see grpc docs
    callback([('macaroon', macaroon)], None)

# now build meta data credentials
auth_creds = grpc.metadata_call_credentials(metadata_callback)

# combine the cert credentials and the macaroon auth credentials
# such that every call is properly encrypted and authenticated
combined_creds = grpc.composite_channel_credentials(cert_creds, auth_creds)

# finally pass in the combined credentials when creating a channel
channel = grpc.secure_channel('localhost:10001', combined_creds)  #example uses 10009, but my user ports are 10001-3

#create the stub (some frameworks just call this the "client")
stub = lnrpc.LightningStub(channel)

print(stub.GetInfo(ln.GetInfoRequest()))
