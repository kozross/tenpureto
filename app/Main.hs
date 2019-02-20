module Main where

import           Options.Applicative
import           Data.Semigroup                 ( (<>) )
import           Tenpureto
import           Control.Monad.IO.Class
import           Data

data Command
    = Create
            { templateName :: Maybe String
            , runUnattended :: Bool
            }
    | Update
            { maybeTemplateName :: Maybe String
            , runUnattended :: Bool
            }

template :: Parser String
template = strOption
    (long "template" <> metavar "<repository>" <> help
        "Template repository name or URL"
    )

unattended :: Parser Bool
unattended = switch (long "unattended" <> help "Do not ask anything")

create :: Parser Command
create = Create <$> (optional template) <*> unattended

update :: Parser Command
update = Update <$> (optional template) <*> unattended

run :: Command -> IO ()
run Create { templateName = t, runUnattended = u } = createProject
    withClonedRepository
    PreliminaryProjectConfiguration { preSelectedTemplate = t
                                    , preSelectedBranches = []
                                    , preVariableValues   = []
                                    }
    u
run Update { maybeTemplateName = t, runUnattended = u } = updateProject
    withClonedRepository
    PreliminaryProjectConfiguration { preSelectedTemplate = t
                                    , preSelectedBranches = []
                                    , preVariableValues   = []
                                    }
    u

main :: IO ()
main = run =<< customExecParser p opts
  where
    commands = subparser
        (  command
                "create"
                (info (create <**> helper)
                      (progDesc "Create a new project for a template")
                )
        <> command
               "update"
               (info (update <**> helper)
                     (progDesc "Update a project for a template")
               )
        )
    opts = info (commands <**> helper) fullDesc
    p    = prefs showHelpOnEmpty
