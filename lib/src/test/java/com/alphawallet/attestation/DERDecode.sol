/* DER Decoding */
/* Stormbird 2018 */

// Very simple demonstration of decoding DER format in Solidity.
// Note that this is a work in progress and is only intended to show very basic decoding.
// Example test DER input code: 0x060f2b060104018b3a7379010fbaef9a15
// The object identifier for this DER would be 1.3.6.1.4.1.1466.115.121.1.15.123456789

// Questions: This decoder should handle custom type definitions. How do we provide those type definitions?
// Would they be encoded into the contract on an ad-hoc basis, per use case?
// Should the contract have dynamic types which can be entered after deployment?

// Major limitations of this first draft:
//	- any IA5 string decoded has to be 32 bytes or less.
//	- Only handles up to 40 translation objects.
//
// Draft 2 should decode any length input and codify how to add type definitions


pragma solidity ^0.4.20;

contract DerDecode
{
    address owner;

    bytes1 constant int BOOLEAN_TAG         = bytes1(0x01);
    bytes1 constant int INTEGER_TAG         = bytes1(0x02);
    bytes1 constant int BIT_STRING_TAG      = bytes1(0x03);
    bytes1 constant int OCTET_STRING_TAG    = bytes1(0x04);
    bytes1 constant int NULL_TAG            = bytes1(0x05);
    bytes1 constant int OBJECT_IDENTIFIER_TAG = bytes1(0x06);
    bytes1 constant int EXTERNAL_TAG        = bytes1(0x08);
    bytes1 constant int ENUMERATED_TAG      = bytes1(0x0a); // decimal 10
    bytes1 constant int SEQUENCE_TAG        = bytes1(0x10); // decimal 16
    bytes1 constant int SEQUENCE_OF_TAG     = bytes1(0x10); // for completeness - used to model a SEQUENCE of the same type.
    bytes1 constant int SET_TAG             = bytes1(0x11); // decimal 17
    bytes1 constant int SET_OF_TAG          = bytes1(0x11);

    bytes1 constant int NUMERIC_STRING_TAG  = bytes1(0x12); // decimal 18
    bytes1 constant int PRINTABLE_STRING_TAG = bytes1(0x13); // decimal 19
    bytes1 constant int T61_STRING_TAG      = bytes1(0x14); // decimal 20
    bytes1 constant int VIDEOTEX_STRING_TAG = bytes1(0x15); // decimal 21
    bytes1 constant int IA5_STRING_TAG      = bytes1(0x16); // decimal 22
    bytes1 constant int UTC_TIME_TAG        = bytes1(0x17); // decimal 23
    bytes1 constant int GENERALIZED_TIME_TAG = bytes1(0x18); // decimal 24
    bytes1 constant int GRAPHIC_STRING_TAG  = bytes1(0x19); // decimal 25
    bytes1 constant int VISIBLE_STRING_TAG  = bytes1(0x1a); // decimal 26
    bytes1 constant int GENERAL_STRING_TAG  = bytes1(0x1b); // decimal 27
    bytes1 constant int UNIVERSAL_STRING_TAG = bytes1(0x1c); // decimal 28
    bytes1 constant int BMP_STRING_TAG      = bytes1(0x1e); // decimal 30
    bytes1 constant int UTF8_STRING_TAG     = bytes1(0x0c); // decimal 12

    uint256 constant IA5_CODE = uint256(bytes32("IA5")); //tags for disambiguating content
    uint256 constant DEROBJ_CODE = uint256(bytes32("OBJID"));

    event Value(uint256 indexed val);
    event RtnStr(bytes val);
    event RtnS(string val);

    function DerDecode (

    ) public
    {
        owner = msg.sender;
    }

    function decodeAttestation(bytes attestation) public view returns(uint256[])
    {
        {
        Status memory data;
        uint objCodeIndex = 0;
        uint decodeIndex = 0;
        uint length = byteCode.length;



        }



    }

    function decodeDER(bytes byteCode) public view returns(uint256[]) //limit for decoded input is 32 bytes for first draft
    {
        uint256[] memory objCodes = new uint256[](40); //arbitrary limit for testing - handle up to 40 translation objects
        Status memory data;
        uint objCodeIndex = 0;
        uint decodeIndex = 0;
        uint length = byteCode.length;

        //need decodeDERLength
        //first get tag of next object
        while (decodeIndex < (length - 2) && byteCode[decodeIndex] != 0)
        {
            //get tag
            bytes1 tag = byteCode[decodeIndex++];
            require((tag & 0x20) == 0); //assert primitive
            require((tag & 0xC0) == 0); //assert universal type

            if ((tag & 0x1f) == IA5_STRING_TAG)
            {
                objCodes[objCodeIndex++] = IA5_CODE;
                data = decodeIA5String(byteCode, objCodes, objCodeIndex, decodeIndex);
                objCodeIndex = data.objCodeIndex;
                decodeIndex = data.decodeIndex;
            }
            else if ((tag & 0x1f) == OBJECT_IDENTIFIER_TAG)
            {
                objCodes[objCodeIndex++] = DEROBJ_CODE;
                data = decodeObjectIdentifier(byteCode, objCodes, objCodeIndex, decodeIndex);
                objCodeIndex = data.objCodeIndex;
                decodeIndex = data.decodeIndex;
            }
        }

        uint256[] memory objCodesComplete = new uint256[](objCodeIndex);
        for (uint i = 0; i < objCodeIndex; i++) objCodesComplete[i] = objCodes[i];

        return objCodesComplete;
    }

    function decodeIA5String(bytes byteCode, uint256[] objCodes, uint objCodeIndex, uint decodeIndex) private view returns(Status)
    {
        uint length = uint(byteCode[decodeIndex++]);
        bytes32 store = 0;
        for (uint j = 0; j < length; j++) store |= bytes32(byteCode[decodeIndex++] & 0xFF) >> (j * 8);
        objCodes[objCodeIndex++] = uint256(store);
        Status memory retVal;
        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }

    struct Status {
        uint decodeIndex;
        uint objCodeIndex;
    }

    function decodeObjectIdentifier(bytes byteCode, uint256[] objCodes, uint objCodeIndex, uint decodeIndex) private view returns(Status)
    {
        uint length = uint(byteCode[decodeIndex++]);

        Status memory retVal;

        //1. decode leading pair
        uint subIDEndIndex = decodeIndex;

        while ((byteCode[subIDEndIndex] & 0x80) == 0x80)
        {
            require(subIDEndIndex < byteCode.length);
            subIDEndIndex++;
        }

        uint subidentifier = 0;
        for (uint i = decodeIndex; i <= subIDEndIndex; i++)
        {
            uint256 subId = uint256(byteCode[i] & 0x7f) << ((subIDEndIndex - i) * 7);
            subidentifier |= subId;
        }

        if (subidentifier < 40)
        {
            objCodes[objCodeIndex++] = 0;
            objCodes[objCodeIndex++] = subidentifier;
        }
        else if (subidentifier < 80)
        {
            objCodes[objCodeIndex++] = 1;
            objCodes[objCodeIndex++] = subidentifier - 40;
        }
        else
        {
            objCodes[objCodeIndex++] = 2;
            objCodes[objCodeIndex++] = subidentifier - 80;
        }

        subIDEndIndex++;

        while (subIDEndIndex < (decodeIndex + length) && byteCode[subIDEndIndex] != 0)
        {
            subidentifier = 0;
            uint256 subIDStartIndex = subIDEndIndex;

            while ((byteCode[subIDEndIndex] & 0x80) == 0x80)
            {
                require(subIDEndIndex < byteCode.length);
                subIDEndIndex++;
            }
            subidentifier = 0;
            for (uint256 j = subIDStartIndex; j <= subIDEndIndex; j++)
            {
                subId = uint256(byteCode[j] & 0x7f) << ((subIDEndIndex - j) * 7);
                subidentifier |= subId;
            }
            objCodes[objCodeIndex++] = subidentifier;
            subIDEndIndex++;
        }

        decodeIndex += length;

        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }

    function endContract() public
    {
        if(msg.sender == owner)
        {
            selfdestruct(owner);
        }
        else revert();
    }
}