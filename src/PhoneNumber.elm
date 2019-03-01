module PhoneNumber exposing
    ( Country
    , NumberType(..)
    , NumberTypeData
    , ValidationConfig
    , anyType
    , matches
    , valid
    )

import Regex exposing (Regex)


type alias Country =
    { id : String
    , countryCode : String
    , internationalPrefix : Maybe String
    , nationalPrefix : Maybe String
    , generalNumberPattern : Regex
    , numberTypes : List NumberTypeData
    }


type NumberType
    = FixedLine
    | Mobile
    | TollFree
    | PremiumRate
    | SharedCost
    | PersonalNumber
    | Voip
    | Pager
    | Uan
    | Emergency
    | Voicemail
    | ShortCode
    | StandardRate
    | CarrierSpecific
    | SmsServices
    | NoInternationalDialling


type alias NumberTypeData =
    { numberType : NumberType
    , exampleNumber : String
    , pattern : Regex
    }


type alias ValidationConfig =
    { countries : List Country
    , types : List NumberType
    , defaultCountry : Maybe Country
    }



-- API


valid : ValidationConfig -> String -> Bool
valid config number =
    case matches config number of
        [] ->
            False

        _ ->
            True


matches : ValidationConfig -> String -> List ( Country, List NumberType )
matches config number =
    let
        sanitizedNumber =
            sanitizeNumber number

        countriesToCheck =
            if config.types == anyType then
                config.countries

            else
                List.map withConfiguredTypes config.countries

        withConfiguredTypes country =
            { country
                | numberTypes =
                    List.filter (\opt -> List.member opt.numberType config.types) country.numberTypes
            }
    in
    List.filterMap (matchingCountry sanitizedNumber) countriesToCheck


anyType : List NumberType
anyType =
    [ FixedLine
    , Mobile
    , TollFree
    , PremiumRate
    , SharedCost
    , PersonalNumber
    , Voip
    , Pager
    , Uan
    , Emergency
    , Voicemail
    , ShortCode
    , StandardRate
    , CarrierSpecific
    , SmsServices
    , NoInternationalDialling
    ]



-- HELPERS


matchingCountry : String -> Country -> Maybe ( Country, List NumberType )
matchingCountry number country =
    let
        maybeLocalNumber =
            localizeNumber country number

        matchesSpec localNumber desc =
            regexExactMatch desc.pattern localNumber
    in
    case maybeLocalNumber of
        Nothing ->
            Nothing

        Just localNumber ->
            Just
                ( country
                , country.numberTypes
                    |> List.filter (matchesSpec localNumber)
                    |> List.map .numberType
                )


localizeNumber : Country -> String -> Maybe String
localizeNumber country number =
    case country.internationalPrefix of
        Nothing ->
            Just number

        Just prefix ->
            let
                prefixLength =
                    String.length prefix

                countryCodeLength =
                    String.length country.countryCode
            in
            if String.startsWith "+" number then
                if
                    number
                        |> String.dropLeft 1
                        |> String.left countryCodeLength
                        |> (==) country.countryCode
                then
                    Just <| String.dropLeft (countryCodeLength + 1) number

                else
                    Nothing

            else if String.startsWith prefix number then
                if
                    number
                        |> String.dropLeft prefixLength
                        |> String.left countryCodeLength
                        |> (==) country.countryCode
                then
                    Just <| String.dropLeft (prefixLength + countryCodeLength) number

                else
                    Nothing

            else
                Just number


sanitizeNumber : String -> String
sanitizeNumber str =
    String.filter (\c -> c /= ' ') str


regexExactMatch : Regex -> String -> Bool
regexExactMatch regex str =
    case Regex.find regex str of
        [ match ] ->
            match.match == str

        _ ->
            False
