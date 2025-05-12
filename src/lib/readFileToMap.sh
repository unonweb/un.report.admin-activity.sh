function readFileToMap() { # result ${filePath}
	local -n result=${1}
	local filePath=${2}	
	local ignoreComments=true

	if [[ ! -e "${filePath}" ]]; then
		echo -e "${RED}ERROR: File not found: ${filePath}${RESET}"
		return 1
  	fi

	# Read the file line by line
	while IFS='=' read -r key value; do
		if [[ ${ignoreComments} == true ]] && [[ "${key}" == \#* ]]; then
        	continue
		fi
		# Trim leading and trailing whitespace from key and value
		key="${key#"${key%%[![:space:]]*}"}"  # Trim leading whitespace
		key="${key%"${key##*[![:space:]]}"}"  # Trim trailing whitespace
		value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
		value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace

		# Store the key-value pair in the associative array
		result["${key}"]="${value}"
	done <"${filePath}"
}