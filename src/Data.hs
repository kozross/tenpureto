{-# LANGUAGE OverloadedStrings #-}

module Data where

import           Data.Text                      ( Text )
import           Data.Set                       ( Set )
import           Data.Map                       ( Map )
import           Data.HashMap.Strict.InsOrd     ( InsOrdHashMap )
import           Data.Yaml                      ( FromJSON(..)
                                                , ToJSON(..)
                                                , (.:)
                                                , (.=)
                                                )
import qualified Data.Yaml                     as Y
import           Git                            ( Committish )
import           Control.Applicative
import           Path
import           Logging

data PreliminaryProjectConfiguration = PreliminaryProjectConfiguration
        { preSelectedTemplate :: Maybe Text
        , preTargetDirectory :: Maybe (Path Abs Dir)
        , prePreviousTemplateCommit :: Maybe Committish
        , preSelectedBranches :: Maybe (Set Text)
        , preVariableValues :: Maybe (Map Text Text)
        }
        deriving (Show)

data FinalTemplateConfiguration = FinalTemplateConfiguration
        { selectedTemplate :: Text
        , targetDirectory :: Path Abs Dir
        }
        deriving (Show)

newtype FinalUpdateConfiguration = FinalUpdateConfiguration
        { previousTemplateCommit :: Committish
        }
        deriving (Show)

data FinalProjectConfiguration = FinalProjectConfiguration
        { baseBranch :: Text
        , featureBranches :: Set Text
        , variableValues :: Map Text Text
        }
        deriving (Show)

data TemplateBranchInformation = TemplateBranchInformation
        { branchName :: Text
        , isBaseBranch :: Bool
        , requiredBranches :: Set Text
        , branchVariables :: InsOrdHashMap Text Text
        , templateYaml :: TemplateYaml
        }
        deriving (Show)

newtype TemplateInformation = TemplateInformation
        { branchesInformation :: [TemplateBranchInformation]
        }
        deriving (Show)

data TemplateYaml = TemplateYaml
        { variables :: InsOrdHashMap Text Text
        , features :: Set Text
        }
        deriving (Show)

instance Semigroup PreliminaryProjectConfiguration where
    (<>) a b = PreliminaryProjectConfiguration
        { preSelectedTemplate = preSelectedTemplate a <|> preSelectedTemplate b
        , preTargetDirectory = preTargetDirectory a <|> preTargetDirectory b
        , prePreviousTemplateCommit = prePreviousTemplateCommit a
                                          <|> prePreviousTemplateCommit b
        , preSelectedBranches = preSelectedBranches a <|> preSelectedBranches b
        , preVariableValues = preVariableValues a <|> preVariableValues b
        }

instance Pretty PreliminaryProjectConfiguration where
    pretty cfg = (align . vsep)
        [ "Template:                 "
            <+> (align . pretty) (preSelectedTemplate cfg)
        , "Target directory:         "
            <+> (align . pretty) (preTargetDirectory cfg)
        , "Previous template commit: "
            <+> (align . pretty . show) (prePreviousTemplateCommit cfg)
        , "Selected branches:        "
            <+> (align . pretty) (preSelectedBranches cfg)
        , "Variable values:          "
            <+> (align . pretty) (preVariableValues cfg)
        ]

instance Pretty FinalProjectConfiguration where
    pretty cfg = (align . vsep)
        [ "Base branch:     " <+> (align . pretty) (baseBranch cfg)
        , "Feature branches:" <+> (align . pretty) (featureBranches cfg)
        , "Variable values: " <+> (align . pretty) (variableValues cfg)
        ]

instance Pretty FinalUpdateConfiguration where
    pretty cfg = (align . vsep)
        [ "Previous template commit:"
              <+> (align . pretty) (previousTemplateCommit cfg)
        ]

instance Pretty TemplateBranchInformation where
    pretty cfg = (align . vsep)
        [ "Branch name:      " <+> (align . pretty) (branchName cfg)
        , "Base branch:      " <+> (align . pretty) (isBaseBranch cfg)
        , "Required branches:" <+> (align . pretty) (requiredBranches cfg)
        , "Branche variables:" <+> (align . pretty) (branchVariables cfg)
        ]

instance Pretty TemplateInformation where
    pretty cfg = (align . vsep)
        ["Branches:" <+> (align . pretty) (branchesInformation cfg)]

instance Pretty TemplateYaml where
    pretty cfg = (align . vsep)
        [ "Variables:" <+> (align . pretty) (variables cfg)
        , "Features: " <+> (align . pretty) (features cfg)
        ]

instance FromJSON TemplateYaml where
    parseJSON (Y.Object v) =
        TemplateYaml <$> v .: "variables" <*> v .: "features"
    parseJSON _ = fail "Invalid template YAML definition"

instance ToJSON TemplateYaml where
    toJSON TemplateYaml { variables = v, features = f } =
        Y.object ["variables" .= v, "features" .= f]

instance Semigroup TemplateYaml where
    (<>) a b = TemplateYaml { variables = variables a <> variables b
                            , features  = features a <> features b
                            }

instance Monoid TemplateYaml where
    mempty = TemplateYaml { variables = mempty, features = mempty }
