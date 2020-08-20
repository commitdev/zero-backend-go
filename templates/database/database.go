package database

import (
	"fmt"
	"log"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/<% index .Params `database` %>"
	"github.com/joho/godotenv"
)

var env map[string]string

type Database struct {
	*gorm.DB
}

const postgresConnString = "sslmode=disable user=%s password=%s host=%s port=%s dbname=%s"
const mysqlConnString = "%s:%s@tcp(%s:%s)/%s"

func getConnectionStringTemplate(engine string) string {
	if engine == "mysql" {
		return mysqlConnString
	}
	if engine == "postgres" {
		return postgresConnString
	}
	return ""
}

func getConnectionString() string {
	godotenv.Load()
	env, _ = godotenv.Read()

	connectionString := fmt.Sprintf(
		getConnectionStringTemplate(env["DB_ENGINE"]),
		env["DB_USERNAME"],
		env["DB_PASSWORD"],
		env["DB_HOST"],
		env["DB_PORT"],
		env["DB_DATABASE"],
	)
	return connectionString
}

func Connect() *Database {
	db, err := gorm.Open(env["DB_ENGINE"], getConnectionString())

	if err != nil {
		fmt.Println(err)
	}
	database := Database{db}

	return &database
}

func (database *Database) Disconnect() {
	database.Close()
	log.Println("Database connection terminated.")
}

func (database *Database) TestConnection() {
	rows, _ := database.Raw("select 1").Rows()
	for rows.Next() {
		var result string
		rows.Scan(&result)
		fmt.Println(result)
	}
}
