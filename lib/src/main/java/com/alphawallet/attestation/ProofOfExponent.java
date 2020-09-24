package com.alphawallet.attestation;

import com.alphawallet.token.tools.Numeric;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.SecureRandom;

import org.bouncycastle.asn1.ASN1Encodable;
import org.bouncycastle.asn1.ASN1EncodableVector;
import org.bouncycastle.asn1.ASN1InputStream;
import org.bouncycastle.asn1.ASN1OctetString;
import org.bouncycastle.asn1.ASN1OutputStream;
import org.bouncycastle.asn1.ASN1Sequence;
import org.bouncycastle.asn1.DEROctetString;
import org.bouncycastle.asn1.DERSequence;
import org.bouncycastle.math.ec.ECPoint;

public class ProofOfExponent implements ASNEncodable, Verifiable{
  private final ECPoint base;
  private final ECPoint riddle;
  private final ECPoint tPoint;
  private final BigInteger challenge;
  private final byte[] encoding;

  public ProofOfExponent(ECPoint base, ECPoint riddle, ECPoint tPoint, BigInteger challenge)
  {
    this.base = base;
    this.riddle = riddle;
    this.tPoint = tPoint;
    this.challenge = challenge;
    this.encoding = makeEncoding(base, riddle, tPoint, challenge);
    System.out.println(Numeric.toHexString(this.encoding));
  }

  public ProofOfExponent(byte[] derEncoded)
  {
    this.encoding = derEncoded;
    try
    {
      ASN1InputStream input = new ASN1InputStream(derEncoded);
      ASN1Sequence asn1 = ASN1Sequence.getInstance(input.readObject());
      ASN1OctetString baseEnc = ASN1OctetString.getInstance(asn1.getObjectAt(0));
      this.base = AttestationCrypto.decodePoint(baseEnc.getOctets());
      ASN1OctetString riddleEnc = ASN1OctetString.getInstance(asn1.getObjectAt(1));
      this.riddle = AttestationCrypto.decodePoint(riddleEnc.getOctets());
      ASN1OctetString challengeEnc = ASN1OctetString.getInstance(asn1.getObjectAt(2));
      this.challenge = new BigInteger(challengeEnc.getOctets());
      ASN1OctetString tPointEnc = ASN1OctetString.getInstance(asn1.getObjectAt(3));
      this.tPoint = AttestationCrypto.decodePoint(tPointEnc.getOctets());
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
    if (!verify()) {
      throw new IllegalArgumentException("The proof is not valid");
    }
  }

  private byte[] makeEncoding(ECPoint base, ECPoint riddle, ECPoint tPoint, BigInteger challenge) {
    try {
    ASN1EncodableVector res = new ASN1EncodableVector();
    byte[] comp1 = base.getEncoded(false);
    byte[] comp2 = riddle.getEncoded(false);
    byte[] comp3 = challenge.toByteArray();
    byte[] comp4 = tPoint.getEncoded(false);

    System.out.println(Numeric.toHexString(comp1));
    System.out.println(Numeric.toHexString(comp2));
    System.out.println(Numeric.toHexString(comp3));
    System.out.println(Numeric.toHexString(comp4));

    DEROctetString baseOctet = new DEROctetString(comp1);

    System.out.println(Numeric.toHexString(baseOctet.getEncoded()));


    res.add(new DEROctetString(base.getEncoded(false)));
    res.add(new DEROctetString(riddle.getEncoded(false)));
    res.add(new DEROctetString(challenge.toByteArray()));
    res.add(new DEROctetString(tPoint.getEncoded(false)));
    return new DERSequence(res).getEncoded();
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

//  public byte[] getEncoded()
//          throws IOException
//  {
//    ASN1Encodable obj;
//
//    ByteArrayOutputStream bOut = new ByteArrayOutputStream();
//    ASN1OutputStream aOut = new ASN1OutputStream(bOut);
//
//    aOut.writeObject(this);
//
//    return bOut.toByteArray();
//  }

  public ECPoint getBase() {
    return base;
  }

  public ECPoint getRiddle() {
    return riddle;
  }

  public ECPoint getPoint() {
    return tPoint;
  }

  public BigInteger getChallenge() {
    return challenge;
  }

  @Override
  public byte[] getDerEncoding() {
    return encoding;
  }

  @Override
  public boolean verify() {
    AttestationCrypto crypto = new AttestationCrypto(new SecureRandom());
    // TODO refactor into the POK class
    return crypto.verifyProof(this);
  }
}
