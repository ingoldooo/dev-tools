#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash

source ${BASH_SOURCE%/*}/colors.sh
source ${BASH_SOURCE%/*}/logger.sh
source ${BASH_SOURCE%/*}/time.sh
source ${BASH_SOURCE%/*}/signature.sh

source ${BASH_SOURCE%/*}/tools.sh
source ${BASH_SOURCE%/*}/error-handling.sh
source ${BASH_SOURCE%/*}/cli-params.sh
source ${BASH_SOURCE%/*}/folder-filters.sh
source ${BASH_SOURCE%/*}/file-tools.sh
